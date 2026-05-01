class_name MigrationRunner
extends RefCounted

const MIGRATION_DIR: String = "res://data/migrations"
const MIGRATION_EXTENSION: String = ".sql"
const VERSION_TABLE_SQL: String = """
CREATE TABLE IF NOT EXISTS schema_version (
	id INTEGER PRIMARY KEY CHECK (id = 1),
	version INTEGER NOT NULL CHECK (version >= 0),
	migration_name TEXT NOT NULL DEFAULT '',
	applied_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
"""
const VERSION_ROW_SQL: String = """
INSERT OR IGNORE INTO schema_version (id, version, migration_name)
VALUES (1, 0, 'baseline');
"""


static func run_pending_migrations(database: Object) -> bool:
	if database == null:
		push_error("MigrationRunner requires a database object.")
		return false
	if not database.has_method("query"):
		push_error("MigrationRunner database object must expose query(sql: String).")
		return false

	if not _execute_statement(database, "PRAGMA foreign_keys = ON"):
		return false
	if not _execute_statement(database, VERSION_TABLE_SQL):
		return false
	if not _execute_statement(database, VERSION_ROW_SQL):
		return false

	var current_version: int = _get_current_schema_version(database)
	if current_version < 0:
		return false

	var migration_files: PackedStringArray = _get_migration_files()
	for migration_file: String in migration_files:
		var migration_version: int = _get_migration_version(migration_file)
		if migration_version <= current_version:
			continue

		var migration_path: String = "%s/%s" % [MIGRATION_DIR, migration_file]
		var migration_sql: String = _read_text_file(migration_path)
		if migration_sql.is_empty():
			push_error("Migration file is empty or unreadable: %s" % migration_path)
			return false

		if not _execute_script(database, migration_sql):
			push_error("Migration failed: %s" % migration_path)
			return false

		if not _mark_migration_applied(database, migration_version, migration_file):
			return false

		current_version = migration_version

	return true


static func _get_migration_files() -> PackedStringArray:
	var files: PackedStringArray = DirAccess.get_files_at(MIGRATION_DIR)
	var migration_files: PackedStringArray = PackedStringArray()
	for file_name: String in files:
		if file_name.ends_with(MIGRATION_EXTENSION) and _get_migration_version(file_name) > 0:
			migration_files.append(file_name)

	migration_files.sort()
	return migration_files


static func _get_migration_version(file_name: String) -> int:
	var prefix: String = file_name.get_basename().get_slice("_", 0)
	if not prefix.is_valid_int():
		return -1
	return int(prefix)


static func _get_current_schema_version(database: Object) -> int:
	if not _execute_statement(database, "SELECT version FROM schema_version WHERE id = 1"):
		return -1

	# godot-sqlite exposes query results through this property after query(), not as the return value.
	var query_result_value: Variant = database.get("query_result")
	if not (query_result_value is Array):
		push_error("Database did not expose an Array query_result.")
		return -1

	var query_result: Array = query_result_value as Array
	if query_result.is_empty():
		return 0

	var row_value: Variant = query_result[0]
	if not (row_value is Dictionary):
		push_error("Schema version query returned an invalid row.")
		return -1

	var row: Dictionary = row_value as Dictionary
	return int(row.get("version", 0))


static func _read_text_file(path: String) -> String:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open migration file: %s" % path)
		return ""

	var text: String = file.get_as_text()
	file.close()
	return text


static func _mark_migration_applied(database: Object, version: int, migration_name: String) -> bool:
	var escaped_migration_name: String = migration_name.replace("'", "''").trim_suffix(MIGRATION_EXTENSION)
	var sql: String = """
UPDATE schema_version
SET version = %d,
	migration_name = '%s',
	applied_at = CURRENT_TIMESTAMP,
	updated_at = CURRENT_TIMESTAMP
WHERE id = 1 AND version < %d
""" % [version, escaped_migration_name, version]
	return _execute_statement(database, sql)


static func _execute_script(database: Object, sql: String) -> bool:
	var statements: PackedStringArray = _split_sql_statements(sql)
	for statement: String in statements:
		if statement.strip_edges().is_empty():
			continue
		if not _execute_statement(database, statement):
			return false

	return true


static func _execute_statement(database: Object, sql: String) -> bool:
	var result: Variant = database.call("query", sql.strip_edges())
	if result is bool:
		if result:
			return true
		push_error("SQL query failed: %s" % sql.strip_edges())
		return false

	return true


static func _split_sql_statements(sql: String) -> PackedStringArray:
	var statements: PackedStringArray = PackedStringArray()
	var current_statement: String = ""
	var in_single_quote: bool = false
	var in_double_quote: bool = false
	var in_line_comment: bool = false
	var index: int = 0

	while index < sql.length():
		var character: String = sql[index]
		var next_character: String = ""
		if index + 1 < sql.length():
			next_character = sql[index + 1]

		if in_line_comment:
			current_statement += character
			if character == "\n":
				in_line_comment = false
			index += 1
			continue

		if not in_single_quote and not in_double_quote and character == "-" and next_character == "-":
			in_line_comment = true
			current_statement += character + next_character
			index += 2
			continue

		if character == "'" and not in_double_quote:
			in_single_quote = not in_single_quote
			current_statement += character
			index += 1
			continue

		if character == "\"" and not in_single_quote:
			in_double_quote = not in_double_quote
			current_statement += character
			index += 1
			continue

		if character == ";" and not in_single_quote and not in_double_quote:
			statements.append(current_statement.strip_edges())
			current_statement = ""
			index += 1
			continue

		current_statement += character
		index += 1

	if not current_statement.strip_edges().is_empty():
		statements.append(current_statement.strip_edges())

	return statements
