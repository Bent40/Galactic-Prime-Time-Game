PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS races (
	id INTEGER PRIMARY KEY,
	key TEXT NOT NULL UNIQUE,
	name TEXT NOT NULL UNIQUE,
	description TEXT NOT NULL DEFAULT '',
	body_parts TEXT NOT NULL CHECK (json_valid(body_parts)),
	unlocked INTEGER NOT NULL DEFAULT 0 CHECK (unlocked IN (0, 1)),
	created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS skills (
	id INTEGER PRIMARY KEY,
	key TEXT NOT NULL UNIQUE,
	name TEXT NOT NULL UNIQUE,
	description TEXT NOT NULL DEFAULT '',
	primary_stat TEXT NOT NULL CHECK (primary_stat IN ('physique', 'reflexes', 'mind', 'charm')),
	secondary_stat TEXT CHECK (secondary_stat IS NULL OR secondary_stat IN ('physique', 'reflexes', 'mind', 'charm')),
	stat_requirements TEXT NOT NULL DEFAULT '{}' CHECK (json_valid(stat_requirements)),
	base_moment_cost INTEGER NOT NULL DEFAULT 1 CHECK (base_moment_cost >= 0),
	default_cap INTEGER NOT NULL DEFAULT 5 CHECK (default_cap BETWEEN 0 AND 10),
	is_magic INTEGER NOT NULL DEFAULT 0 CHECK (is_magic IN (0, 1)),
	unlock_requirements TEXT NOT NULL DEFAULT '{}' CHECK (json_valid(unlock_requirements)),
	effects TEXT NOT NULL DEFAULT '[]' CHECK (json_valid(effects)),
	created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
	CHECK (secondary_stat IS NULL OR secondary_stat <> primary_stat)
);

CREATE INDEX IF NOT EXISTS idx_skills_primary_stat ON skills(primary_stat);
CREATE INDEX IF NOT EXISTS idx_skills_is_magic ON skills(is_magic);

CREATE TABLE IF NOT EXISTS skill_thresholds (
	id INTEGER PRIMARY KEY,
	skill_id INTEGER NOT NULL,
	level INTEGER NOT NULL CHECK (level BETWEEN 0 AND 10),
	threshold_name TEXT NOT NULL DEFAULT '',
	description TEXT NOT NULL DEFAULT '',
	stat_requirements TEXT NOT NULL DEFAULT '{}' CHECK (json_valid(stat_requirements)),
	effects TEXT NOT NULL DEFAULT '[]' CHECK (json_valid(effects)),
	FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE,
	UNIQUE (skill_id, level)
);

CREATE INDEX IF NOT EXISTS idx_skill_thresholds_skill_id ON skill_thresholds(skill_id);

-- character_id intentionally has no FK: character instances live in JSON saves, not SQLite.
CREATE TABLE IF NOT EXISTS character_skills (
	character_id TEXT NOT NULL,
	skill_id INTEGER NOT NULL,
	starting_level INTEGER NOT NULL DEFAULT 0 CHECK (starting_level BETWEEN 0 AND 10),
	skill_cap INTEGER NOT NULL DEFAULT 5 CHECK (skill_cap BETWEEN 0 AND 10),
	FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE,
	PRIMARY KEY (character_id, skill_id),
	CHECK (starting_level <= skill_cap)
);

CREATE INDEX IF NOT EXISTS idx_character_skills_skill_id ON character_skills(skill_id);

CREATE TABLE IF NOT EXISTS tags (
	id INTEGER PRIMARY KEY,
	key TEXT NOT NULL UNIQUE,
	name TEXT NOT NULL UNIQUE,
	description TEXT NOT NULL DEFAULT '',
	category TEXT NOT NULL DEFAULT 'identity',
	unlock_conditions TEXT NOT NULL DEFAULT '{}' CHECK (json_valid(unlock_conditions)),
	goal_modifier_weights TEXT NOT NULL DEFAULT '{}' CHECK (json_valid(goal_modifier_weights)),
	created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_tags_category ON tags(category);

CREATE TABLE IF NOT EXISTS character_tags (
	character_id TEXT NOT NULL,
	tag_id INTEGER NOT NULL,
	weight INTEGER NOT NULL DEFAULT 1 CHECK (weight >= 0),
	FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE,
	PRIMARY KEY (character_id, tag_id)
);

CREATE INDEX IF NOT EXISTS idx_character_tags_tag_id ON character_tags(tag_id);

CREATE TABLE IF NOT EXISTS items (
	id INTEGER PRIMARY KEY,
	key TEXT NOT NULL UNIQUE,
	name TEXT NOT NULL UNIQUE,
	description TEXT NOT NULL DEFAULT '',
	item_type TEXT NOT NULL,
	tier TEXT NOT NULL DEFAULT 'common',
	stat_requirements TEXT NOT NULL DEFAULT '{}' CHECK (json_valid(stat_requirements)),
	body_parts TEXT NOT NULL DEFAULT '[]' CHECK (json_valid(body_parts)),
	damage_type TEXT,
	damage_amount INTEGER NOT NULL DEFAULT 0 CHECK (damage_amount >= 0),
	base_moment_cost INTEGER CHECK (base_moment_cost IS NULL OR base_moment_cost >= 0),
	range_pattern TEXT NOT NULL DEFAULT '',
	modifier_slots INTEGER NOT NULL DEFAULT 0 CHECK (modifier_slots >= 0),
	effects TEXT NOT NULL DEFAULT '[]' CHECK (json_valid(effects)),
	created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_items_item_type ON items(item_type);
CREATE INDEX IF NOT EXISTS idx_items_tier ON items(tier);

CREATE TABLE IF NOT EXISTS modifiers (
	id INTEGER PRIMARY KEY,
	key TEXT NOT NULL UNIQUE,
	name TEXT NOT NULL UNIQUE,
	description TEXT NOT NULL DEFAULT '',
	modifier_type TEXT NOT NULL,
	tier TEXT NOT NULL DEFAULT 'common',
	effects TEXT NOT NULL DEFAULT '[]' CHECK (json_valid(effects)),
	created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_modifiers_modifier_type ON modifiers(modifier_type);
CREATE INDEX IF NOT EXISTS idx_modifiers_tier ON modifiers(tier);

CREATE TABLE IF NOT EXISTS item_modifiers (
	item_id INTEGER NOT NULL,
	modifier_id INTEGER NOT NULL,
	slot_index INTEGER NOT NULL DEFAULT 0 CHECK (slot_index >= 0),
	FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE,
	FOREIGN KEY (modifier_id) REFERENCES modifiers(id) ON DELETE CASCADE,
	PRIMARY KEY (item_id, modifier_id),
	UNIQUE (item_id, slot_index)
);

CREATE INDEX IF NOT EXISTS idx_item_modifiers_modifier_id ON item_modifiers(modifier_id);

CREATE TABLE IF NOT EXISTS conditions (
	id TEXT PRIMARY KEY,
	name TEXT NOT NULL UNIQUE,
	description TEXT NOT NULL DEFAULT '',
	resistance_type TEXT NOT NULL CHECK (resistance_type IN ('Physical', 'Affliction', 'Psychic', 'None')),
	target_body_parts TEXT NOT NULL DEFAULT '[]' CHECK (json_valid(target_body_parts)),
	spread_rules TEXT NOT NULL DEFAULT '{}' CHECK (json_valid(spread_rules)),
	created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_conditions_resistance_type ON conditions(resistance_type);

CREATE TABLE IF NOT EXISTS condition_tiers (
	condition_id TEXT NOT NULL,
	tier INTEGER NOT NULL CHECK (tier >= 1),
	name TEXT NOT NULL DEFAULT '',
	description TEXT NOT NULL DEFAULT '',
	clock_advance INTEGER NOT NULL DEFAULT 1 CHECK (clock_advance >= 0),
	shock_tier INTEGER NOT NULL DEFAULT 0 CHECK (shock_tier >= 0),
	forced_action_type TEXT CHECK (forced_action_type IS NULL OR forced_action_type IN ('Body', 'Tool')),
	effects TEXT NOT NULL DEFAULT '[]' CHECK (json_valid(effects)),
	FOREIGN KEY (condition_id) REFERENCES conditions(id) ON DELETE CASCADE,
	PRIMARY KEY (condition_id, tier)
);

CREATE INDEX IF NOT EXISTS idx_condition_tiers_condition_id ON condition_tiers(condition_id);

CREATE TABLE IF NOT EXISTS enemies (
	id INTEGER PRIMARY KEY,
	key TEXT NOT NULL UNIQUE,
	name TEXT NOT NULL UNIQUE,
	description TEXT NOT NULL DEFAULT '',
	category TEXT NOT NULL CHECK (category IN ('Mob', 'Elite', 'Boss', 'Super Boss')),
	body_parts TEXT NOT NULL DEFAULT '[]' CHECK (json_valid(body_parts)),
	stat_block TEXT NOT NULL DEFAULT '{}' CHECK (json_valid(stat_block)),
	resistances TEXT NOT NULL DEFAULT '{}' CHECK (json_valid(resistances)),
	reward_table TEXT NOT NULL DEFAULT '[]' CHECK (json_valid(reward_table)),
	created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_enemies_category ON enemies(category);

CREATE TABLE IF NOT EXISTS enemy_phases (
	id INTEGER PRIMARY KEY,
	enemy_id INTEGER NOT NULL,
	phase_number INTEGER NOT NULL CHECK (phase_number >= 1),
	name TEXT NOT NULL DEFAULT '',
	trigger_condition TEXT NOT NULL,
	behavior TEXT NOT NULL DEFAULT '{}' CHECK (json_valid(behavior)),
	effects TEXT NOT NULL DEFAULT '[]' CHECK (json_valid(effects)),
	FOREIGN KEY (enemy_id) REFERENCES enemies(id) ON DELETE CASCADE,
	UNIQUE (enemy_id, phase_number)
);

CREATE INDEX IF NOT EXISTS idx_enemy_phases_enemy_id ON enemy_phases(enemy_id);

CREATE TABLE IF NOT EXISTS patron_goals (
	id INTEGER PRIMARY KEY,
	key TEXT NOT NULL UNIQUE,
	name TEXT NOT NULL UNIQUE,
	description TEXT NOT NULL DEFAULT '',
	goal_type TEXT NOT NULL,
	source_type TEXT NOT NULL DEFAULT 'Patron' CHECK (source_type IN ('Patron', 'Corporate', 'Crowd')),
	tag_id INTEGER,
	trigger_conditions TEXT NOT NULL DEFAULT '{}' CHECK (json_valid(trigger_conditions)),
	reward TEXT NOT NULL DEFAULT '{}' CHECK (json_valid(reward)),
	effects TEXT NOT NULL DEFAULT '[]' CHECK (json_valid(effects)),
	created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_patron_goals_goal_type ON patron_goals(goal_type);
CREATE INDEX IF NOT EXISTS idx_patron_goals_source_type ON patron_goals(source_type);
CREATE INDEX IF NOT EXISTS idx_patron_goals_tag_id ON patron_goals(tag_id);

CREATE TABLE IF NOT EXISTS npc (
	id INTEGER PRIMARY KEY,
	key TEXT NOT NULL UNIQUE,
	name TEXT NOT NULL,
	floor INTEGER CHECK (floor IS NULL OR floor >= 0),
	role TEXT NOT NULL DEFAULT '',
	description TEXT NOT NULL DEFAULT '',
	base_inclinations TEXT NOT NULL DEFAULT '[]' CHECK (json_valid(base_inclinations)),
	created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_npc_floor ON npc(floor);
CREATE INDEX IF NOT EXISTS idx_npc_role ON npc(role);
