#!/usr/bin/env python3
"""Front-rework mockup assembler (KAN-6 mockup gate, owner: "lets do the mockups").

Generates five self-contained HTML frames (1600x1000) implementing the owner's
structural spec docs/ux-designs/hud-v2/ARCHITECTURE.md in the APPROVED visual
identity (docs/ux-designs/demo-slice-2026-07-19/DESIGN.md). Every number is
PLACEHOLDER (R14). Content is real slice data: data/demo_run.json party +
Incine-Dile den, data/enemies.json parts, data/recruit_loadouts.json Sasha,
data/mod_center_offers.json (BLESSED 2026-08-19).

Render: /opt/pw-browsers/chromium --headless=new --screenshot at 1600x1000 @2x
(see render.sh next to this file). Emoji glyphs are placeholder art per the
approved mockups; ARCHITECTURE.md §7 bans them only in the final release.
"""
import math, os

OUT = os.path.dirname(os.path.abspath(__file__))

# ---------------------------------------------------------------- identity ---
CSS = """
:root{
  --bg:#04050d; --panel:#090c1a; --panel2:#0d1020; --glass:rgba(9,12,26,.86);
  --cyan:#00d4ff; --gold:#c8a84b; --danger:#ff2255; --success:#00ff88;
  --text:#b8c8e0; --muted:#3a4560; --border:#1a2540; --purple:#a855f7;
  --mythic:#ec4899; --fire:#ff7a2f; --num:'Courier New',monospace;
}
*{margin:0;padding:0;box-sizing:border-box}
body{background:#000;font-family:system-ui,-apple-system,sans-serif;color:var(--text)}
.mk{position:relative;width:1600px;height:1000px;background:var(--bg);overflow:hidden}
.bbar{position:absolute;top:0;left:0;right:0;height:44px}
.topstrip{position:absolute;top:44px;left:0;right:0;height:118px}
.mid{position:absolute;top:162px;left:0;right:0;bottom:120px}
.bottomstrip{position:absolute;bottom:34px;left:0;right:0;height:86px}
.ticker{position:absolute;bottom:0;left:0;right:0;height:34px}
.mono{font-family:var(--num)}
.lbl{text-transform:uppercase;letter-spacing:3px;font-size:8px;color:var(--muted);font-weight:700}
.pill{display:inline-flex;align-items:center;gap:5px;padding:3px 9px;border-radius:4px;
      border:1px solid var(--border);font-family:var(--num);font-size:11px;font-weight:700}
.p-cyan{border-color:rgba(0,212,255,.5);color:var(--cyan);background:rgba(0,212,255,.07)}
.p-gold{border-color:rgba(200,168,75,.5);color:var(--gold);background:rgba(200,168,75,.08)}
.p-purple{border-color:rgba(168,85,247,.5);color:var(--purple);background:rgba(168,85,247,.08)}
.p-danger{border-color:rgba(255,34,85,.55);color:var(--danger);background:rgba(255,34,85,.08)}
.p-success{border-color:rgba(0,255,136,.45);color:var(--success);background:rgba(0,255,136,.06)}
.p-fire{border-color:rgba(255,122,47,.55);color:var(--fire);background:rgba(255,122,47,.08)}
.p-mute{color:var(--muted)}
/* broadcast bar ------------------------------------------------------------ */
.bbar{display:flex;align-items:center;gap:14px;padding:0 16px;
      background:var(--panel);border-bottom:1px solid var(--border)}
.live{display:inline-flex;align-items:center;gap:7px;padding:4px 12px;border-radius:4px;
      border:1px solid rgba(255,34,85,.6);color:#fff;font-weight:800;font-size:12px;letter-spacing:2px}
.live .dot{width:8px;height:8px;border-radius:50%;background:var(--danger);animation:blink 1.1s infinite}
@keyframes blink{0%,49%{opacity:1}50%,100%{opacity:.15}}
.rec{color:var(--muted);font-family:var(--num);font-size:11px;letter-spacing:1px}
.brand{position:absolute;left:0;right:0;text-align:center;pointer-events:none}
.brand b{font-size:19px;font-weight:900;letter-spacing:7px;color:var(--cyan);
         text-shadow:0 0 20px rgba(0,212,255,.7)}
.brand span{display:block;font-size:8px;letter-spacing:4px;color:var(--gold);margin-top:1px}
.watch{margin-left:auto;display:flex;align-items:center;gap:10px;z-index:2}
.watch .n{font-family:var(--num);font-size:13px;color:var(--text)}
.momus-chip{padding:4px 12px;border-radius:14px;border:1px solid rgba(236,72,153,.55);
            color:var(--mythic);font-weight:800;font-size:11px;letter-spacing:3px}
/* top strip ----------------------------------------------------------------- */
.topstrip{display:flex;gap:10px;padding:8px 12px;border-bottom:1px solid var(--border);
          background:linear-gradient(180deg,var(--panel) 0%,rgba(9,12,26,.4) 100%)}
.selpanel{flex:0 0 400px;display:flex;gap:10px;padding:8px 10px;background:var(--panel2);
          border:1px solid var(--border);border-radius:6px;position:relative}
.selpanel.onclock{border-color:rgba(200,168,75,.55);box-shadow:0 0 22px rgba(200,168,75,.18)}
.selglyph{flex:0 0 54px;height:54px;border-radius:9px;background:var(--panel);border:1px solid var(--border);
          display:flex;align-items:center;justify-content:center;font-size:28px;align-self:center}
.selbody{flex:1;min-width:0;display:flex;flex-direction:column;gap:3px;justify-content:center}
.selname{font-size:14px;font-weight:800;color:#e8f2ff;letter-spacing:.5px;padding-right:96px;white-space:nowrap}
.selname small{display:block;color:var(--muted);font-weight:700;font-size:8px;letter-spacing:1px;margin-top:2px;max-width:250px;overflow:hidden;text-overflow:ellipsis}
.selrow{display:flex;gap:5px;flex-wrap:wrap;align-items:center}
.selrow .pill{font-size:9px;padding:2px 7px}
.onclock-tag{position:absolute;top:-1px;right:-1px;padding:3px 9px;border-radius:0 6px 0 6px;
             background:rgba(200,168,75,.15);border:1px solid rgba(200,168,75,.5);
             color:var(--gold);font-size:8px;letter-spacing:2px;font-weight:800}
.topcenter{flex:1;display:flex;flex-direction:column;gap:6px;min-width:0}
.shortcuts{display:flex;gap:6px;justify-content:flex-start}
.sc{padding:4px 11px;border-radius:4px;border:1px solid var(--border);background:var(--panel2);
    color:var(--muted);font-size:8px;letter-spacing:2px;font-weight:800;text-transform:uppercase}
.sc.active{border-color:rgba(0,212,255,.5);color:var(--cyan);background:rgba(0,212,255,.07)}
.timeline{flex:1;display:flex;align-items:center;gap:12px;background:var(--panel2);
          border:1px solid var(--border);border-radius:6px;padding:4px 12px}
.track{flex:1;position:relative;height:58px;margin-top:6px}
.track .rail-line{position:absolute;left:0;right:0;top:12px;height:2px;background:var(--border)}
.tickmark{position:absolute;top:8px;width:2px;height:10px;background:var(--muted);opacity:.6}
.ticknum{position:absolute;top:-6px;transform:translateX(-50%);font-family:var(--num);
         font-size:8px;color:var(--muted)}
.nowmark{position:absolute;top:2px;width:3px;height:22px;background:var(--cyan);
         box-shadow:0 0 10px rgba(0,212,255,.8)}
.tl-chip{position:absolute;top:26px;transform:translateX(-50%);white-space:nowrap;
         font-size:8px;letter-spacing:1px;font-weight:800;padding:1px 6px;border-radius:3px;
         border:1px solid var(--border);background:var(--panel)}
.tl-chip.lane1{top:43px}
.tl-bandlbl{position:absolute;top:-3px;white-space:nowrap;font-size:7px;letter-spacing:1px;font-weight:800;background:rgba(4,5,13,.92);padding:1px 5px;border-radius:3px}
.tl-band{position:absolute;top:11px;height:4px;border-radius:2px}
.odds{flex:0 0 300px;display:flex;flex-direction:column;gap:4px;justify-content:center;
      background:var(--panel2);border:1px solid var(--border);border-radius:6px;padding:8px 12px}
.odds .row{display:flex;justify-content:space-between;align-items:baseline;gap:8px}
.odds .k{font-size:8px;letter-spacing:2px;color:var(--muted);font-weight:800;text-transform:uppercase}
.odds .v{font-family:var(--num);font-size:12px;font-weight:700;color:var(--text)}
/* middle -------------------------------------------------------------------- */
.mid{display:flex}
.rail{flex:0 0 168px;padding:10px 8px;display:flex;flex-direction:column;gap:8px;
      background:linear-gradient(90deg,rgba(9,12,26,.9),rgba(9,12,26,.55));
      border-right:1px solid var(--border);z-index:5}
.pcard{border:1px solid var(--border);border-radius:6px;background:var(--glass);padding:7px 8px;
       display:flex;flex-direction:column;gap:4px;position:relative}
.pcard.active{border-color:rgba(200,168,75,.6);box-shadow:0 0 18px rgba(200,168,75,.22)}
.pcard.selected{border-color:rgba(0,212,255,.55)}
.pcard .hd{display:flex;align-items:center;gap:7px}
.pcard .g{width:26px;height:26px;border-radius:6px;background:var(--panel);border:1px solid var(--border);
          display:flex;align-items:center;justify-content:center;font-size:14px}
.pcard .nm{font-size:11px;font-weight:800;color:#dce8fa;line-height:1.1}
.pcard .nm small{display:block;font-size:7px;letter-spacing:1px;color:var(--muted);font-weight:700}
.hpbar{height:4px;border-radius:2px;background:var(--border);overflow:hidden}
.hpbar i{display:block;height:100%}
.flagrow{display:flex;gap:4px;flex-wrap:wrap}
.flag{font-size:7px;letter-spacing:1px;font-weight:800;padding:1px 5px;border-radius:3px;
      border:1px solid var(--border);color:var(--muted)}
.f-danger{border-color:rgba(255,34,85,.5);color:var(--danger)}
.f-gold{border-color:rgba(200,168,75,.5);color:var(--gold)}
.f-cyan{border-color:rgba(0,212,255,.5);color:var(--cyan)}
.f-purple{border-color:rgba(168,85,247,.5);color:var(--purple)}
.f-success{border-color:rgba(0,255,136,.45);color:var(--success)}
.f-fire{border-color:rgba(255,122,47,.5);color:var(--fire)}
.statmini{display:flex;justify-content:space-between;font-family:var(--num);font-size:8px;color:var(--muted)}
/* world --------------------------------------------------------------------- */
.world{flex:1;position:relative;overflow:hidden;min-width:0}
.stage{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;
       perspective:1500px}
.board{transform:rotateX(46deg) rotateZ(-2deg) translateY(40px);transform-style:preserve-3d}
.feed{position:absolute;inset:0;pointer-events:none;
      background:repeating-linear-gradient(0deg,rgba(255,255,255,.016) 0 1px,transparent 1px 3px)}
.vign{position:absolute;inset:0;pointer-events:none;
      background:radial-gradient(ellipse at 50% 45%,transparent 55%,rgba(0,0,0,.55) 100%)}
.cammark{position:absolute;width:18px;height:18px;border:2px solid rgba(0,212,255,.25);pointer-events:none}
.cm-tl{top:10px;left:12px;border-right:0;border-bottom:0}
.cm-tr{top:10px;right:12px;border-left:0;border-bottom:0}
.cm-bl{bottom:10px;left:12px;border-right:0;border-top:0}
.cm-br{bottom:10px;right:12px;border-left:0;border-top:0}
.feedtag{position:absolute;top:12px;left:40px;font-size:9px;letter-spacing:2px;color:var(--muted);font-weight:700}
.rectag{position:absolute;top:12px;right:44px;font-size:9px;letter-spacing:2px;color:var(--danger);font-weight:800}
.phasetags{position:absolute;top:10px;left:50%;transform:translateX(-50%);display:flex;gap:6px}
.token{position:absolute;display:flex;flex-direction:column;align-items:center;gap:3px;z-index:6;
       transform:translate(-50%,-100%)}
.tok-g{width:52px;height:52px;border-radius:11px;background:rgba(9,12,26,.9);border:2px solid var(--border);
       display:flex;align-items:center;justify-content:center;font-size:26px;position:relative}
.token.boss .tok-g{width:84px;height:84px;font-size:46px;border-radius:16px;border-color:rgba(255,122,47,.65);
                   box-shadow:0 0 34px rgba(255,122,47,.35)}
.token.ally-act .tok-g{border-color:var(--gold);box-shadow:0 0 22px rgba(200,168,75,.45)}
.token.ally-sel .tok-g{border-color:var(--cyan);box-shadow:0 0 22px rgba(0,212,255,.45)}
.token.conceal .tok-g{border-style:dashed;border-color:rgba(0,212,255,.5);opacity:.75}
.tok-name{font-size:9px;letter-spacing:1.5px;font-weight:800;padding:2px 8px;border-radius:3px;
          background:rgba(4,5,13,.85);border:1px solid var(--border);color:#dbe7f8;white-space:nowrap}
.tok-hp{width:52px;height:3px;border-radius:2px;background:rgba(4,5,13,.9);overflow:hidden}
.tok-hp i{display:block;height:100%}
.tok-conds{position:absolute;top:-9px;right:-9px;display:flex;gap:2px}
.cond-dot{width:16px;height:16px;border-radius:50%;font-size:9px;display:flex;align-items:center;
          justify-content:center;background:rgba(4,5,13,.95);border:1px solid var(--danger)}
.conelegend{position:absolute;left:16px;top:44px;z-index:6;background:rgba(4,5,13,.82);
             border:1px solid var(--border);border-radius:7px;padding:9px 11px;display:flex;
             flex-direction:column;gap:5px}
.lg-row{display:flex;align-items:center;gap:8px}
.lg-sw{width:20px;height:12px;border:1.5px solid;border-radius:2px;flex:0 0 20px}
.lg-l{font-size:8px;letter-spacing:1.5px;font-weight:800;color:var(--text);width:150px}
.lg-n{font-size:8px;letter-spacing:.5px;color:var(--muted)}
.eye{display:inline-flex;align-items:center;gap:4px;padding:1px 6px;border-radius:3px;
     border:1px solid var(--muted);font-size:7px;letter-spacing:1.5px;font-weight:800;color:var(--muted);
     background:rgba(4,5,13,.9)}
.eye.seen{border-color:rgba(255,34,85,.7);color:var(--danger)}
.intent{display:flex;align-items:center;gap:5px;padding:3px 8px;border-radius:5px;margin-bottom:3px;
        background:rgba(4,5,13,.92);border:1px solid var(--border);white-space:nowrap}
.intent b{font-size:15px;line-height:1}
.intent .ilab{font-size:8px;letter-spacing:1.5px;font-weight:800;font-family:var(--num)}
.intent.i-attack{border-color:rgba(255,34,85,.65)} .intent.i-attack .ilab{color:var(--danger)}
.intent.i-aoe{border-color:rgba(255,122,47,.7)} .intent.i-aoe .ilab{color:var(--fire)}
.intent.i-heavy{border-color:rgba(255,34,85,.85);box-shadow:0 0 14px rgba(255,34,85,.35)}
.intent.i-heavy .ilab{color:#fff}
.intent.i-buff{border-color:rgba(0,255,136,.6)} .intent.i-buff .ilab{color:var(--success)}
.intent.i-debuff{border-color:rgba(168,85,247,.6)} .intent.i-debuff .ilab{color:var(--purple)}
.intent.i-unknown{border-color:var(--muted)} .intent.i-unknown .ilab{color:var(--muted)}
.intent.hov{border-color:var(--cyan);box-shadow:0 0 16px rgba(0,212,255,.45)}
.intent-tip{position:absolute;left:50%;transform:translateX(-50%);bottom:calc(100% + 8px);z-index:12;
            width:268px;background:rgba(4,5,13,.97);border:1px solid rgba(0,212,255,.55);border-radius:7px;
            padding:10px 12px;text-align:left;box-shadow:0 6px 26px rgba(0,0,0,.6)}
.intent-tip .tt{font-size:11px;font-weight:900;letter-spacing:1.5px;color:#eaf6ff}
.intent-tip .tk{font-size:8px;letter-spacing:2px;font-weight:800;color:var(--muted);margin-top:2px}
.intent-tip .tb{font-size:10px;line-height:1.6;color:var(--text);margin-top:6px}
.intent-tip .tb b{color:var(--cyan)}
.intent-tip .tr{display:flex;gap:5px;flex-wrap:wrap;margin-top:7px}
.fa-count{font-family:var(--num);font-size:10px;color:var(--gold);margin-left:6px}
.groundtag{position:absolute;z-index:5;font-size:8px;letter-spacing:1.5px;font-weight:800;
           padding:2px 7px;border-radius:3px;background:rgba(4,5,13,.8);border:1px solid var(--border);
           transform:translate(-50%,-50%);white-space:nowrap}
/* right column -------------------------------------------------------------- */
.rightcol{position:absolute;top:10px;right:10px;bottom:10px;width:308px;display:flex;
          flex-direction:column;gap:10px;z-index:7}
.rpanel{background:var(--glass);border:1px solid var(--border);border-radius:7px;padding:11px 13px;
        backdrop-filter:blur(4px)}
.rpanel h4{font-size:9px;letter-spacing:3px;color:var(--muted);font-weight:800;margin-bottom:8px;
           text-transform:uppercase;display:flex;justify-content:space-between;align-items:center}
.hypehead{display:flex;justify-content:space-between;align-items:baseline}
.hypehead .v{font-family:var(--num);font-size:26px;font-weight:800;color:var(--gold)}
.hypehead .v small{font-size:12px;color:var(--muted)}
.hypebar{height:9px;border-radius:4px;background:var(--border);overflow:hidden;margin:7px 0 6px}
.hypebar i{display:block;height:100%;background:linear-gradient(90deg,#7a6320,var(--gold));
           box-shadow:0 0 12px rgba(200,168,75,.6)}
.bandrow{display:flex;justify-content:space-between;align-items:center}
.band{font-size:12px;font-weight:900;letter-spacing:2px;color:var(--gold)}
.goal{border:1px solid rgba(0,212,255,.4);border-radius:6px;padding:9px 11px;margin-top:9px;
      background:rgba(0,212,255,.05)}
.goal .t{font-size:12px;font-weight:900;letter-spacing:1px;color:#eaf6ff}
.goal .d{font-size:10px;color:var(--text);margin:4px 0 7px;line-height:1.45}
.goal .r{display:flex;gap:6px}
.part{display:flex;align-items:center;gap:8px;padding:4px 0;border-bottom:1px solid rgba(26,37,64,.6)}
.part:last-child{border-bottom:0}
.part .pn{flex:1;font-size:10px;letter-spacing:1px;font-weight:700;color:var(--text)}
.part .ph{font-family:var(--num);font-size:10px;font-weight:700}
.part .st{font-size:7px;letter-spacing:1px;font-weight:800;padding:1px 5px;border-radius:3px;
          border:1px solid var(--border);color:var(--muted)}
.part.hidden-part .pn,.part.hidden-part .ph{color:var(--muted);font-style:italic}
.knowrow{display:flex;gap:5px;flex-wrap:wrap;margin-top:8px}
.telegraph{margin-top:9px;border:1px solid rgba(255,122,47,.5);border-radius:6px;padding:8px 10px;
           background:rgba(255,122,47,.06)}
.telegraph .t{font-size:10px;font-weight:900;letter-spacing:1px;color:var(--fire)}
.telegraph .d{font-size:9px;color:var(--text);margin-top:3px;line-height:1.5}
/* bottom -------------------------------------------------------------------- */
.bottomstrip{display:flex;gap:10px;padding:8px 12px;border-top:1px solid var(--border);
             background:var(--panel);z-index:8}
.chat{flex:0 0 400px;border:1px solid var(--border);border-radius:6px;background:var(--panel2);
      padding:7px 10px;display:flex;flex-direction:column;gap:3px}
.chat .m{font-size:9px;color:var(--muted);line-height:1.4}
.chat .m b{color:var(--text)}
.chat .hd{display:flex;justify-content:space-between;align-items:center}
.launcher{flex:1;display:flex;align-items:center;gap:9px;position:relative}
.whoclock{display:flex;flex-direction:column;gap:2px;margin-right:2px}
.whoclock .w{font-size:8px;letter-spacing:2px;color:var(--muted);font-weight:800}
.whoclock .n{font-size:12px;font-weight:800;color:var(--gold)}
.abtn{padding:11px 20px;border-radius:5px;border:1px solid var(--border);background:var(--panel2);
      font-size:11px;font-weight:800;letter-spacing:2px;color:var(--text);position:relative}
.abtn.open{border-color:rgba(0,212,255,.55);color:var(--cyan);background:rgba(0,212,255,.07)}
.abtn .badge{position:absolute;top:-7px;right:-7px;width:16px;height:16px;border-radius:50%;
             background:var(--gold);color:#04050d;font-size:9px;font-weight:900;display:flex;
             align-items:center;justify-content:center;box-shadow:0 0 10px rgba(200,168,75,.7)}
.endturn{margin-left:auto;padding:12px 26px;border-radius:5px;border:1px solid rgba(255,34,85,.55);
         color:#fff;font-weight:900;letter-spacing:2px;font-size:12px;background:rgba(255,34,85,.08)}
.conseq{position:absolute;right:0;top:-26px;font-size:10px;color:var(--muted)}
.conseq b{color:var(--cyan)}
.conseq .to{color:var(--gold)}
/* flyout + preview ----------------------------------------------------------- */
.flyout{position:absolute;bottom:100%;margin-bottom:10px;background:var(--glass);border:1px solid
        rgba(0,212,255,.4);border-radius:7px;padding:9px;display:flex;flex-direction:column;gap:5px;
        min-width:250px;backdrop-filter:blur(4px);box-shadow:0 -6px 30px rgba(0,0,0,.5)}
.fly-h{font-size:8px;letter-spacing:2px;color:var(--muted);font-weight:800;padding:0 4px}
.frow{display:flex;align-items:center;gap:9px;padding:6px 8px;border-radius:5px;border:1px solid transparent}
.frow.sel{border-color:rgba(0,212,255,.5);background:rgba(0,212,255,.07)}
.frow.dis{opacity:.45}
.frow .fn{flex:1;font-size:11px;font-weight:800;color:#dfeaff}
.frow .fn small{display:block;font-size:8px;color:var(--muted);font-weight:600;letter-spacing:.5px;margin-top:1px}
.frow .fc{font-family:var(--num);font-size:9px;color:var(--muted);white-space:nowrap}
.preview{position:absolute;bottom:100%;margin-bottom:10px;background:var(--glass);
         border:1px solid rgba(200,168,75,.5);border-radius:7px;padding:12px 14px;width:300px;
         backdrop-filter:blur(4px);box-shadow:0 -6px 30px rgba(0,0,0,.5)}
.preview .t{font-size:13px;font-weight:900;letter-spacing:2px;color:var(--gold)}
.preview .kv{display:flex;justify-content:space-between;font-size:10px;margin-top:5px}
.preview .kv .k{color:var(--muted);letter-spacing:1px;font-weight:700;text-transform:uppercase;font-size:8px}
.preview .kv .v{font-family:var(--num);font-weight:700;color:var(--text)}
.preview ul{list-style:none;margin:8px 0;border-top:1px solid var(--border);padding-top:7px}
.preview li{font-size:10px;line-height:1.6;color:var(--text)}
.preview li b{color:var(--cyan)}
.pv-btns{display:flex;gap:7px;margin-top:9px}
.pv-btns .ok{flex:1;text-align:center;padding:8px;border-radius:5px;border:1px solid rgba(0,255,136,.5);
             color:var(--success);font-weight:900;font-size:10px;letter-spacing:2px}
.pv-btns .no{flex:0 0 84px;text-align:center;padding:8px;border-radius:5px;border:1px solid var(--border);
             color:var(--muted);font-weight:800;font-size:10px;letter-spacing:2px}
/* ticker --------------------------------------------------------------------- */
.ticker{display:flex;align-items:center;gap:12px;padding:0 16px;
        background:var(--panel);border-top:1px solid var(--border)}
.ticker .who{display:flex;align-items:center;gap:8px;color:var(--mythic);font-weight:900;
             letter-spacing:3px;font-size:11px}
.ticker .line{font-size:12px;font-style:italic;color:#d8c9e2}
.ticker .hint{margin-left:auto;font-size:8px;letter-spacing:2px;color:var(--muted);font-weight:700}
/* overlays ------------------------------------------------------------------- */
.watermark{position:absolute;left:242px;bottom:130px;z-index:5;font-size:8px;letter-spacing:2px;
           color:rgba(58,69,96,.9);font-weight:800;text-align:left;line-height:1.7}
.dim{position:absolute;inset:0;background:rgba(2,3,8,.68);z-index:20;backdrop-filter:blur(2px)}
.ask{position:absolute;left:50%;bottom:118px;transform:translateX(-50%);z-index:24;width:560px;
     background:var(--glass);border:1px solid rgba(255,34,85,.55);border-radius:9px;padding:15px 18px;
     box-shadow:0 0 44px rgba(255,34,85,.25);backdrop-filter:blur(5px)}
.popup{position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);z-index:24;width:960px;
       background:var(--panel);border:1px solid rgba(200,168,75,.5);border-radius:10px;
       box-shadow:0 0 60px rgba(0,0,0,.7);overflow:hidden}
.cursor-tip{position:absolute;z-index:9;background:rgba(4,5,13,.92);border:1px solid rgba(0,212,255,.5);
            border-radius:5px;padding:6px 9px;font-size:9px;line-height:1.6}
"""

# ------------------------------------------------------------------ helpers ---
def hexgrid(cols, rows, s, fire=(), terrain=(), dim=()):
    """Flat-top odd-q offset grid -> svg polygons."""
    out, w, h = [], s * 1.5, s * math.sqrt(3)
    for q in range(cols):
        for r in range(rows):
            cx = 60 + q * w
            cy = 50 + r * h + (h / 2 if q % 2 else 0)
            pts = " ".join(f"{cx+s*math.cos(math.radians(a)):.1f},{cy+s*math.sin(math.radians(a)):.1f}"
                           for a in range(0, 360, 60))
            key = (q, r)
            fill, op, stroke = "#0c1122", ".9", "#1a2540"
            if key in fire:    fill, op, stroke = "#3a1c0c", ".95", "rgba(255,122,47,.7)"
            if key in terrain: fill, op, stroke = "#101a24", ".95", "rgba(0,212,255,.22)"
            if key in dim:     op = ".35"
            out.append(f'<polygon points="{pts}" fill="{fill}" fill-opacity="{op}" stroke="{stroke}" stroke-width="1.2"/>')
    return "\n".join(out)

def hex_center(q, r, s):
    return (60 + q * s * 1.5, 50 + r * s * math.sqrt(3) + (s * math.sqrt(3) / 2 if q % 2 else 0))

def wall(x, y, wl, ang=0):
    return (f'<g transform="translate({x},{y}) rotate({ang})">'
            f'<rect x="{-wl/2}" y="-7" width="{wl}" height="14" rx="2" fill="#232c48" stroke="#31406b" stroke-width="1.5"/>'
            f'<rect x="{-wl/2}" y="-7" width="{wl}" height="5" rx="2" fill="#31406b" opacity=".7"/></g>')

def door(x, y, wl, state, ang=0):
    col = "#c8a84b" if state == "closed" else "#00d4ff"
    fill = "rgba(200,168,75,.25)" if state == "closed" else "rgba(0,212,255,.12)"
    dash = "" if state == "closed" else 'stroke-dasharray="5 4"'
    return (f'<g transform="translate({x},{y}) rotate({ang})">'
            f'<rect x="{-wl/2}" y="-6" width="{wl}" height="12" rx="2" fill="{fill}" stroke="{col}" stroke-width="1.6" {dash}/></g>')

def trashcan(x, y, burning=False):
    g = f'<ellipse cx="{x}" cy="{y}" rx="13" ry="9" fill="#1b2340" stroke="#31406b" stroke-width="1.5"/>' \
        f'<ellipse cx="{x}" cy="{y-4}" rx="13" ry="9" fill="#242e52" stroke="#31406b" stroke-width="1.5"/>'
    if burning:
        g += f'<circle cx="{x}" cy="{y-6}" r="16" fill="rgba(255,122,47,.28)"/>' \
             f'<circle cx="{x}" cy="{y-6}" r="7" fill="rgba(255,170,60,.55)"/>'
    return g

def token(left, top, glyph, name, hp_pct, hp_col, cls="", conds=(), sub="", intent=None, tip=None, eye=None):
    """intent: (icon, label, kind) — the Slay-the-Spire read of what this enemy does NEXT.
    tip: (title, kind_line, body, chips) — the hover explanation (rendered open on one token
    per frame to show the interaction)."""
    cond = "".join(f'<span class="cond-dot" title="{c[1]}">{c[0]}</span>' for c in conds)
    condwrap = f'<span class="tok-conds">{cond}</span>' if cond else ""
    subhtml = f'<span class="tok-name" style="border-color:rgba(0,212,255,.4);color:var(--cyan)">{sub}</span>' if sub else ""
    intent_html = ""
    if intent:
        icon, label, kind = intent
        intent_html = (f'<span class="intent i-{kind}{" hov" if tip else ""}">'
                       f'<b>{icon}</b><span class="ilab">{label}</span></span>')
    tip_html = ""
    if tip:
        title, kindline, body, chips = tip
        tip_html = (f'<div class="intent-tip"><div class="tt">{title}</div>'
                    f'<div class="tk">{kindline}</div><div class="tb">{body}</div>'
                    f'<div class="tr">{chips}</div></div>')
    eye_html = ""
    if eye:
        seen, label = eye
        eye_html = f'<span class="eye{" seen" if seen else ""}">👁 {label}</span>'
    return (f'<div class="token {cls}" style="left:{left}%;top:{top}%">{tip_html}{intent_html}'
            f'<div class="tok-g">{glyph}{condwrap}</div>'
            f'<span class="tok-name">{name}</span>'
            f'<span class="tok-hp"><i style="width:{hp_pct}%;background:{hp_col}"></i></span>{eye_html}{subhtml}</div>')


def pill(cls, txt): return f'<span class="pill {cls}">{txt}</span>'
def flag(cls, txt): return f'<span class="flag {cls}">{txt}</span>'

def bbar(rec="00:07:41", watching="4,102,338"):
    return f'''<div class="bbar">
      <span class="live"><span class="dot"></span>LIVE</span><span class="rec">REC {rec}</span>
      <div class="brand"><b>GALACTIC PRIME TIME</b><span>◆ COSMIC CASINO · VIP TABLE — THE INCINERATOR</span></div>
      <div class="watch"><span style="color:var(--muted)">👁</span><span class="n">{watching}</span>
      <span class="lbl">watching</span><span class="momus-chip">🦩 MOMUS</span></div></div>'''

def shortcuts(active=None):
    names = ["Wagers", "Divine", "Social", "Encyclopedia", "Achievements", "Quests", "⚙"]
    return '<div class="shortcuts">' + "".join(
        f'<span class="sc{" active" if n == active else ""}">{n}</span>' for n in names) + "</div>"

def timeline(chips, bands, now=3.0, extra=""):
    """chips: (clock_pos, label, class); bands: (from,to,color,label)"""
    parts = ['<span class="pill p-purple">CLOCK 3</span><span class="pill p-cyan">MOMENT 07</span>',
             '<div class="track"><div class="rail-line"></div>']
    for i in range(11):
        x = i * 10
        parts.append(f'<span class="tickmark" style="left:{x}%"></span><span class="ticknum" style="left:{x}%">{i}</span>')
    parts.append(f'<span class="nowmark" style="left:{now*10}%"></span>')
    for a, b, col, lab in bands:
        parts.append(f'<span class="tl-band" style="left:{a*10}%;width:{(b-a)*10}%;background:{col};box-shadow:0 0 8px {col}"></span>')
        if lab: parts.append(f'<span class="tl-bandlbl" style="left:{a*10}%;color:{col}">{lab}</span>')
    for chip in chips:
        pos, lab, cls = chip[0], chip[1], chip[2]
        lane = chip[3] if len(chip) > 3 else 0
        parts.append(f'<span class="tl-chip {cls}{" lane1" if lane else ""}" style="left:{pos*10}%">{lab}</span>')
    parts.append("</div>")
    parts.append(f'<span class="lbl" style="white-space:nowrap">next reset · clock 4</span>{extra}')
    return f'<div class="timeline">{"".join(parts)}</div>'

def odds_panel(rows, note):
    r = "".join(f'<div class="row"><span class="k">{k}</span><span class="v" style="{s}">{v}</span></div>'
                for k, v, s in rows)
    return f'<div class="odds">{r}<div style="font-size:8px;color:var(--muted);line-height:1.5">{note}</div></div>'

def pcard(glyph, name, sub, hp, hpcol, flags, stat, cls=""):
    fl = "".join(flags)
    return (f'<div class="pcard {cls}"><div class="hd"><span class="g">{glyph}</span>'
            f'<span class="nm">{name}<small>{sub}</small></span></div>'
            f'<div class="hpbar"><i style="width:{hp}%;background:{hpcol}"></i></div>'
            f'<div class="flagrow">{fl}</div><div class="statmini">{stat}</div></div>')

def crowd_panel(goal_t, goal_d, goal_r, delta="+12", hype="68", band="ELECTRIC ⚡", spot="DARIO", tag="“Reckless”"):
    return f'''<div class="rpanel">
      <h4>Crowd <span class="pill p-gold" style="font-size:8px">{delta}</span></h4>
      <div class="hypehead"><span class="v">{hype}<small> / 100</small></span><span class="lbl">hype</span></div>
      <div class="hypebar"><i style="width:{hype}%"></i></div>
      <div class="bandrow"><span class="band">{band}</span>
        <span class="flag f-gold">SPOTLIGHT · {spot}</span><span class="flag">{tag}</span></div>
      <div class="goal"><div class="t">🎯 {goal_t}</div><div class="d">{goal_d}</div>
      <div class="r">{goal_r}</div></div></div>'''

def ticker(line, who="MOMUS"):
    return (f'<div class="ticker"><span class="who">🦩 {who}</span><span class="line">{line}</span>'
            f'<span class="hint">CLICK FOR FULL EVENT LOG ▸</span></div>')

def watermark(frame):
    return (f'<div class="watermark">MOCKUP · {frame}<br>STRUCTURE PER hud-v2/ARCHITECTURE.md §2 · '
            f'IDENTITY PER demo-slice DESIGN.md<br>PLACEHOLDER NUMBERS · R14 · EMOJI = PLACEHOLDER ART</div>')

def page(title, body):
    return (f'<!doctype html><html><head><meta charset="utf-8"><title>{title}</title>'
            f'<style>{CSS}</style></head><body><div class="mk">{body}</div></body></html>')

# --------------------------------------------------------- den board (1-3) ---
FIRE_HEXES = {(7, 2), (8, 2), (8, 3)}
def den_board(cone=False, sasha_ring=True):
    """VISION CONES CARRY STATE (owner ruling 2026-08-19, decision 5 amendment):
    a sight cone is NEUTRAL while its owner has spotted nobody, and turns RED the
    moment it has someone — so the player reads 'am I seen?' off the board, and can
    never confuse a vision cone with an ATTACK cone (which stays hazard-orange)."""
    svg_parts = [hexgrid(13, 7, 42, fire=FIRE_HEXES)]
    svg_parts.append(wall(180, 88, 150, -2))          # north wall segment
    svg_parts.append(wall(560, 60, 190, 0))
    svg_parts.append(wall(90, 300, 130, 88))          # west wall
    svg_parts.append(door(760, 310, 74, "closed", 90))  # service hatch (east, closed)
    svg_parts.append(door(150, 470, 84, "open", 0))     # kennel gate (south-west, open)
    svg_parts.append(trashcan(600, 170, burning=True))
    svg_parts.append(trashcan(210, 420))
    svg_parts.append(trashcan(430, 480))
    if sasha_ring:
        cx, cy = hex_center(2, 4, 42)
        svg_parts.append(f'<circle cx="{cx}" cy="{cy}" r="86" fill="none" stroke="rgba(0,212,255,.35)" '
                         f'stroke-width="1.5" stroke-dasharray="6 6"/>')
    bx, by = hex_center(6, 2, 42)
    # 1) the ATTACK cone — hazard orange, dashed. Never confusable with sight.
    if cone:
        svg_parts.append(f'<path d="M {bx} {by} L {bx-260} {by+190} A 330 330 0 0 0 {bx-40} {by+320} Z" '
                         f'fill="rgba(255,122,47,.16)" stroke="rgba(255,122,47,.6)" stroke-width="1.8" '
                         f'stroke-dasharray="7 5"/>')
    # 2) the boss's VISION cone — RED: it has the party (R30 front arc, sight 2xMind)
    svg_parts.append(f'<path d="M {bx} {by} L {bx-196} {by+126} A 234 234 0 0 0 {bx-48} {by+230} Z" '
                     f'fill="rgba(255,34,85,.13)" stroke="rgba(255,34,85,.6)" stroke-width="1.4"/>')
    # 3) the unread add's VISION cone — NEUTRAL: it has spotted nobody (Sasha is concealed
    #    inside it, which is exactly the state the colour is there to tell you)
    ax, ay = hex_center(1, 2, 42)
    svg_parts.append(f'<path d="M {ax} {ay} L {ax+150} {ay+96} A 180 180 0 0 0 {ax+176} {ay-36} Z" '
                     f'fill="rgba(150,170,205,.10)" stroke="rgba(150,170,205,.45)" stroke-width="1.4"/>')
    svg = f'<svg width="900" height="560" viewBox="0 0 900 560">{"".join(svg_parts)}</svg>'
    tags = ('<span class="groundtag" style="left:70%;top:71%;border-color:rgba(200,168,75,.5);color:var(--gold)">SERVICE HATCH · CLOSED</span>'
            '<span class="groundtag" style="left:20%;top:82%;border-color:rgba(0,212,255,.45);color:var(--cyan)">KENNEL GATE · OPEN</span>'
            '<span class="groundtag" style="left:59%;top:56%;border-color:rgba(255,122,47,.55);color:var(--fire)">🔥 FIRE HEALS IT</span>')
    return f'<div class="stage"><div class="board">{svg}</div></div>{tags}{cone_legend()}'


def cone_legend():
    """Reading key for the three cone colours — the whole point of the ruling."""
    rows = [("rgba(150,170,205,.55)", "rgba(150,170,205,.16)", "VISION · UNAWARE", "nobody spotted — you are hidden"),
            ("rgba(255,34,85,.7)", "rgba(255,34,85,.16)", "VISION · HAS SOMEONE", "it sees a contestant — you are revealed"),
            ("rgba(255,122,47,.7)", "rgba(255,122,47,.18)", "ATTACK CONE", "what the blow will cover")]
    out = ""
    for stroke, fill, label, note in rows:
        out += (f'<div class="lg-row"><span class="lg-sw" style="background:{fill};border-color:{stroke}"></span>'
                f'<span class="lg-l">{label}</span><span class="lg-n">{note}</span></div>')
    return f'<div class="conelegend"><div class="lbl">cone reading</div>{out}</div>'


def den_tokens(mode="ready"):
    """Every enemy carries an intent icon (owner ruling 2026-08-19, decision 2 — the
    Slay-the-Spire read). One is shown hovered to demonstrate the full explanation."""
    toks = []
    if mode == "dodge":
        boss_intent = ("\u26a1", "DASH \u2192 IMANI", "attack")
        boss_tip = ("DASH \u2014 CHARGE THROUGH", "HEAVY \u00b7 RESOLVING NOW \u00b7 DODGEABLE",
                    "Barrels a lane and shoulders whatever it reaches \u2014 <b>4 CRUSH</b> to the torso. "
                    "Next Clock it vents, and <b>that</b> one you cannot dodge.",
                    '<span class="flag f-danger">4 CRUSH</span><span class="flag f-cyan">DODGE OPEN</span>'
                    '<span class="flag f-fire">THEN: \u26d4 VALVE BLAST</span>')
        boss_conds = (("\u26a1", "dashing"),)
    else:
        boss_intent = ("\U0001f525", "CONE \u00b7 WIDE", "aoe")
        boss_tip = ("FLAMETHROWER \u2014 CONE", "AREA \u00b7 RESOLVES CLOCK 5 \u00b7 INTERRUPTIBLE",
                    "Sprays the front arc. Everything caught takes <b>BURN</b> and keeps burning. "
                    "Hit the <b>flamer hand</b> first and the whole thing collapses into a Forced Action.",
                    '<span class="flag f-fire">BURN II</span><span class="flag f-success">INTERRUPT OPEN</span>'
                    '<span class="flag">FRONT ARC ONLY</span>')
        boss_conds = (("\U0001f525", "fire-fed"),)
    toks.append(token(52, 47, "\U0001f40a", "INCINE-DILE", 100, "var(--fire)", "boss", boss_conds,
                      intent=boss_intent, tip=boss_tip, eye=(True, "HAS THE PARTY")))
    # the boss's adds — one read, one not yet read (discovery states, decision 6)
    toks.append(token(71, 63, "\U0001fab3", "LITTLE BROTHER", 100, "var(--danger)", "",
                      intent=("\u2694", "BITE \u00b7 2", "attack"), eye=(True, "HAS DARIO")))
    toks.append(token(24, 55, "\U0001fab3", "LITTLE BROTHER", 100, "var(--danger)", "",
                      intent=("\u2753", "UNREAD", "unknown"), eye=(False, "UNAWARE")))
    imani_cls = "ally-sel" if mode == "dodge" else ""
    toks.append(token(45, 63, "\U0001f6e1", "IMANI", 95, "var(--success)", imani_cls,
                      (("\U0001f4a2", "guard"),) if mode != "dodge" else (("\u2757", "incoming"),)))
    toks.append(token(58, 81, "\U0001f3ad", "DARIO", 88, "var(--gold)", "ally-act",
                      (("\U0001fa78", "bleeding T1"),)))
    toks.append(token(35, 67, "\U0001f0cf", "SASHA", 100, "var(--success)", "conceal", (),
                      sub="CONCEALED \u00b7 r2"))
    if mode == "dodge":
        toks.append('<div style="position:absolute;left:41%;top:51%;width:130px;height:3px;'
                    'background:linear-gradient(90deg,rgba(255,34,85,.9),transparent);transform:rotate(118deg);'
                    'z-index:5;box-shadow:0 0 12px rgba(255,34,85,.8)"></div>')
    return "".join(toks)


def world(board, tokens, extra=""):
    return (f'<div class="world">{board}{tokens}'
            f'<div class="feed"></div><div class="vign"></div>'
            f'<span class="cammark cm-tl"></span><span class="cammark cm-tr"></span>'
            f'<span class="cammark cm-bl"></span><span class="cammark cm-br"></span>'
            f'<span class="feedtag">● FEED 01 · ARENA CAM</span><span class="rectag">● REC</span>'
            f'{extra}</div>')

# ------------------------------------------------------------ shared panels ---
def sel_dario():
    return f'''<div class="selpanel onclock"><span class="onclock-tag">◂ ON THE CLOCK</span>
      <span class="selglyph">🎭</span><div class="selbody">
      <div class="selname">DARIO “ENCORE” <small>THE HEEL YOU PAY TO BOO</small></div>
      <div class="selrow">{pill("p-gold","⚜ ENYO")}{pill("p-cyan","CLOCK 3")}{pill("p-danger","🩸 R-ARM 1/2 · BLEEDING T1")}</div>
      <div class="selrow">{pill("p-gold","📸 CAMERA ×1")}{pill("p-mute","SHOCK 0")}{flag("f-gold","SPOTLIGHT")}{flag("","TAG · RECKLESS")}</div>
      </div></div>'''

def sel_imani_dodge():
    return f'''<div class="selpanel" style="border-color:rgba(255,34,85,.6);box-shadow:0 0 22px rgba(255,34,85,.2)">
      <span class="onclock-tag" style="border-color:rgba(255,34,85,.5);color:var(--danger);background:rgba(255,34,85,.12)">⚠ REACTING</span>
      <span class="selglyph">🛡</span><div class="selbody">
      <div class="selname">IMANI “THE DOOR” <small>THE WALL BETWEEN THE MONSTER AND EVERYONE ELSE</small></div>
      <div class="selrow">{pill("p-gold","⚜ HESTIA")}{pill("p-cyan","CLOCK 3")}{pill("p-danger","INCOMING · DASH")}</div>
      <div class="selrow">{pill("p-mute","REFLEXES 2")}{pill("p-purple","THRESHOLD DIE d4")}{pill("p-mute","SHOCK 0")}</div>
      </div></div>'''

def rail_party(active="dario", sasha_state="CONCEALED"):
    cards = [f'<div class="lbl" style="padding:0 3px">Party — 3 / 6</div>']
    cards.append(pcard("🛡", "IMANI", "the door", 95, "var(--success)",
                       [flag("f-gold", "⚜ HESTIA"),
                        flag("f-success", "READY · CLK 4") if active != "none" else flag("f-success", "✦ FREE"),
                        flag("f-danger", "❗ INCOMING") if active == "imani-dodge" else flag("", "GUARD ✓")],
                       "<span>PHY 5</span><span>RFX 2</span><span>MND 4</span><span>CHA 3</span>",
                       "selected" if active == "imani-dodge" else ""))
    cards.append(pcard("🎭", "DARIO", "encore", 88, "var(--gold)",
                       [flag("f-gold", "⚜ ENYO"),
                        flag("f-gold", "ACTING NOW") if active != "none" else flag("f-success", "✦ FREE"),
                        flag("f-danger", "🩸 R-ARM 1/2")],
                       "<span>PHY 2</span><span>RFX 5</span><span>MND 2</span><span>CHA 5</span>",
                       "active" if active == "dario" else ""))
    cards.append(pcard("🃏", "SASHA", "little shadow", 100, "var(--success)",
                       [flag("f-cyan", sasha_state),
                        flag("", "WAITS · CLK 5") if active != "none" else flag("f-success", "✦ FREE"),
                        flag("f-purple", "MIND 5 · READS FEINTS")],
                       "<span>PHY 3</span><span>RFX 4</span><span>MND 5</span><span>CHA 2</span>"))
    cards.append('<div class="lbl" style="padding:6px 3px 0;opacity:.7">↕ scrolls at 4+ members</div>')
    return f'<div class="rail">{"".join(cards)}</div>'

def inspector_boss(targeting=False):
    def part(name, hp, maxhp, state_flags, cls="", valid=None, pred="", hptxt=None):
        stf = "".join(state_flags)
        v = ""
        if targeting and valid is not None:
            v = (flag("f-success", "VALID") if valid else flag("", "OUT OF ARC")) + \
                (f'<span class="flag f-gold">{pred}</span>' if pred else "")
        if hptxt is None:
            hpc = "var(--success)" if hp / maxhp > .66 else ("var(--gold)" if hp / maxhp > .33 else "var(--danger)")
            hptxt_html = f'<span class="ph" style="color:{hpc}">{hp}/{maxhp}</span>'
        else:
            hptxt_html = f'<span class="ph" style="color:var(--muted)">{hptxt}</span>'
        return f'<div class="part {cls}"><span class="pn">{name}</span>{stf}{v}{hptxt_html}</div>'
    parts = [
        part("HEAD", 7, 7, [flag("", "VISIBLE")], valid=False),
        part("RIGHT HAND · FLAMER", 8, 8, [flag("f-fire", "🔥 WEAPON")], valid=True, pred="2 DMG · BLEED"),
        part("LEFT HAND", 30, 30, [flag("", "VISIBLE")], valid=True, pred="2 DMG · BLEED"),
        part("RIGHT LEG", 15, 15, [flag("", "VISIBLE")], valid=False),
        part("LEFT LEG", 15, 15, [flag("", "VISIBLE")], valid=False),
        part("UNKNOWN INTERNAL STRUCTURE", 0, 1, [flag("f-purple", "SUSPECTED")], "hidden-part", hptxt="🔒 ???"),
    ]
    know = (flag("f-success", "VISIBLE") + flag("f-cyan", "KNOWN") + flag("f-purple", "SUSPECTED")
            + flag("", "HIDDEN") + flag("f-danger", "MISIDENTIFIED?"))
    tele = ('<div class="telegraph"><div class="t">⚠ CURRENT INTENT — FLAMETHROWER</div>'
            '<div class="d">Cone from the right hand · resolves <b class="mono">CLOCK 5</b> · '
            'interrupt window <b class="mono">OPEN</b> — a hit on the flamer hand before then forces the d6.</div></div>')
    resist = (f'<div class="knowrow">{flag("f-gold","AFFLICTION RES 2")}{flag("f-fire","FIRE HEALS — SUSPECTED")}'
              f'{flag("","MIND 1 — feints unreadable")}</div>')
    mode = ('<div class="knowrow" style="margin-bottom:6px">' + flag("f-cyan", "TARGETING — FEINT") +
            flag("", "front arc only") + "</div>") if targeting else ""
    return (f'<div class="rpanel insp"><h4>Inspector — INCINE-DILE <span class="pill p-fire" '
            f'style="font-size:8px">PHASE 1</span></h4>{mode}{"".join(parts)}{resist}'
            f'<div class="knowrow"><span class="lbl" style="letter-spacing:1px">discovery:</span>{know}</div>{tele}</div>')

def launcher(mode="ready"):
    conseq = ('<div class="conseq"><b>FEINT</b> → forces a reaction · sets up <span class="to">PRESSURE STRIKE'
              '</span> · ally openers count — <b>CROSS-CHARACTER CHAIN</b></div>')
    fly = ""
    btn_skills = '<span class="abtn">SKILLS</span>'
    if mode == "targeting":
        btn_skills = '<span class="abtn open">SKILLS</span>'
        fly = f'''<div class="flyout" style="left:270px">
          <div class="fly-h">DARIO — SKILLS</div>
          <div class="frow sel"><span class="fn">FEINT <small>L3 · forces a reaction · opens PRESSURE STRIKE</small></span><span class="fc">1 MOMENT</span></div>
          <div class="frow"><span class="fn">PRESSURE STRIKE <small>L1 · CHAIN — needs FEINT (yours or an ally's, same target)</small></span><span class="fc">1 MOMENT</span></div>
          <div class="frow"><span class="fn">DANCE <small>L2 · STANCE — spectacle while it holds</small></span><span class="fc">1 MOMENT</span></div>
          <div class="frow dis"><span class="fn">🔒 THE LONG CON <small>TIER 2 — Mod-Center offer · FEINT 5 + VIBE CONTROL 3</small></span><span class="fc">—</span></div>
        </div>
        <div class="preview" style="left:540px">
          <div class="t">FEINT</div>
          <div class="kv"><span class="k">Target</span><span class="v">INCINE-DILE · LEFT HAND</span></div>
          <div class="kv"><span class="k">Cost</span><span class="v">1 MOMENT · resolves CLOCK 4</span></div>
          <div class="kv"><span class="k">Read risk</span><span class="v" style="color:var(--success)">NONE — MIND 1</span></div>
          <ul><li>▸ Low damage · applies <b>EXPOSED</b></li>
              <li>▸ Opens <b>PRESSURE STRIKE</b> for the party (same target)</li>
              <li>▸ Crowd goal <b>SHOW-OFF!</b> pays if you land from EXPOSED</li></ul>
          <div class="pv-btns"><span class="ok">CONFIRM ▸</span><span class="no">BACK</span></div>
        </div>'''
    endturn = '''<span class="endturn" title="">END TURN</span>'''
    return f'''<div class="launcher"><div class="whoclock"><span class="w">ON THE CLOCK</span>
      <span class="n">DARIO “ENCORE”</span></div>
      <span class="abtn">↔ MOVE</span><span class="abtn">ATTACK</span>{btn_skills}
      <span class="abtn">FREE ACTIONS<b class="fa-count">1/2</b><span class="badge">!</span></span>{endturn}{conseq}{fly}</div>'''

def chat_panel():
    return '''<div class="chat"><div class="hd"><span class="lbl">chat · party</span>
      <span class="flag f-cyan">2 UNREAD</span><span class="lbl" style="letter-spacing:1px">EXPAND ▴</span></div>
      <div class="m"><b>SASHA:</b> Flamer hand. It vents when you hit it. Watch the valve.</div>
      <div class="m"><b>IMANI:</b> Quit lighting things up — the fire FEEDS it.</div></div>'''

# ---------------------------------------------------------------- frame 1 ----
def frame_ready():
    tl = timeline(
        chips=[(3.0, "DARIO ▸ NOW", "p-gold", 0), (4.0, "IMANI", "p-cyan", 1), (4.6, "🐊 BOSS", "p-fire", 0),
               (5.4, "SASHA", "p-cyan", 1), (7.4, "🔥 BURN II", "p-fire", 1)],
        bands=[], now=3.0)
    odds = odds_panel(
        [("Survival odds", "3 : 1", ""), ("Top bidder", "ENYO ×3.1 ▲", "color:var(--gold)"),
         ("Live wager", "Breach before MOMENT 20", "font-size:10px")],
        "ENYO raises on the bow · ARES eyes a buy-out of Imani · pot 18.2k favor — click for full wagers")
    right = crowd_panel("SHOW-OFF!", "Land a hit from an <b style='color:var(--cyan)'>Exposed</b> state — make it look easy.",
                        pill("p-success", "+40 HYPE") + pill("p-purple", "⏱ 2 CLOCKS") +
                        '<span class="flag f-gold" style="align-self:center">CHAIN NEXT ROOM · KEEPS 40%</span>')
    body = (bbar()
            + f'<div class="topstrip">{sel_dario()}<div class="topcenter">{shortcuts()}{tl}</div>{odds}</div>'
            + f'<div class="mid">{rail_party()}'
            + world(den_board(cone=True), den_tokens("ready"),
                    '<div class="phasetags">' + pill("p-fire", "PHASE 1") + pill("p-mute", "NETWORK 🔒 HIDDEN") + "</div>")
            + f'<div class="rightcol">{right}{inspector_boss()}</div></div>'
            + f'<div class="bottomstrip">{chat_panel()}{launcher("ready")}</div>'
            + ticker("“—and Dario bows mid-combat, the absolute professional!”")
            + watermark("FRAME 1 · MODE B — PARTY MEMBER READY"))
    return page("HUD v2 — Mode B (ready)", body)

# ---------------------------------------------------------------- frame 2 ----
def frame_targeting():
    tl = timeline(
        chips=[(3.0, "DARIO ▸ NOW", "p-gold", 0), (4.0, "FEINT ⌖ YOUR PREVIEW", "p-cyan", 1),
               (4.6, "🐊 BOSS", "p-fire", 0), (5.6, "SASHA", "p-cyan", 1)],
        bands=[(3.0, 4.0, "rgba(0,212,255,.8)", "YOUR DECLARATION")], now=3.0)
    odds = odds_panel(
        [("Survival odds", "3 : 1", ""), ("Top bidder", "ENYO ×3.1 ▲", "color:var(--gold)"),
         ("Live wager", "Breach before MOMENT 20", "font-size:10px")],
        "Declared actions animate the odds on commit — the house is watching your cursor")
    right = crowd_panel("SHOW-OFF!", "Land a hit from an <b style='color:var(--cyan)'>Exposed</b> state — make it look easy.",
                        pill("p-success", "+40 HYPE") + pill("p-purple", "⏱ 2 CLOCKS"))
    tip = ('<div class="cursor-tip" style="left:47%;top:31%">'
           '<b style="color:var(--cyan)">LEFT HAND</b><br>In range · front arc ✓<br>'
           '<span style="color:var(--gold)">Predicted: 2 DMG · BLEED I</span></div>')
    body = (bbar(rec="00:07:58")
            + f'<div class="topstrip">{sel_dario()}<div class="topcenter">{shortcuts()}{tl}</div>{odds}</div>'
            + f'<div class="mid">{rail_party()}'
            + world(den_board(cone=True), den_tokens("ready"),
                    '<div class="phasetags">' + pill("p-fire", "PHASE 1") + pill("p-cyan", "TARGETING — VALID PARTS LIT") + "</div>" + tip)
            + f'<div class="rightcol">{right}{inspector_boss(targeting=True)}</div></div>'
            + f'<div class="bottomstrip">{chat_panel()}{launcher("targeting")}</div>'
            + ticker("“He’s pointing at the big one. Bold. The odds board certainly thinks so.”")
            + watermark("FRAME 2 · MODE C — TARGETING A BODY PART"))
    return page("HUD v2 — Mode C (targeting)", body)

# ---------------------------------------------------------------- frame 3 ----
def frame_dodge():
    tl = timeline(
        chips=[(3.0, "🐊 BOSS ▸ NOW", "p-danger", 0), (4.2, "DARIO", "p-gold", 1),
               (4.8, "🐊 BOSS", "p-danger", 0), (5.4, "SASHA", "p-cyan", 1)],
        bands=[], now=3.0)
    odds = odds_panel(
        [("Survival odds", "5 : 1 ▼", "color:var(--danger)"), ("Top bidder", "ENYO ×3.4 ▲", "color:var(--gold)"),
         ("Live wager", "Imani eats the dash — 2:1", "font-size:10px")],
        "The table smells blood · ARES doubles his position on the boy")
    right = crowd_panel("PRATFALL!", "Somebody goes down funny. The crowd is not picky about <i>who</i>.",
                        pill("p-success", "+25 HYPE") + pill("p-purple", "⏱ 1 CLOCK"),
                        delta="+4", hype="72", spot="IMANI")
    ask = f'''<div class="ask">
      <div style="display:flex;justify-content:space-between;align-items:baseline">
        <span style="font-size:15px;font-weight:900;letter-spacing:2px;color:#fff">⚡ INCOMING — DASH → IMANI</span>
        <span class="pill p-danger">REACT NOW</span></div>
      <div style="font-size:10px;color:var(--text);margin:7px 0 10px;line-height:1.6">
        Reflexes <b class="mono" style="color:var(--cyan)">2</b> vs dodge threshold
        <b class="mono" style="color:var(--danger)">4</b> — short by 2. Your fallback is the
        <b style="color:var(--purple)">threshold die (d4)</b>: roll <b class="mono">3+</b> to slip it.
        Upgraded dice ride this stat for the whole run.</div>
      <div style="display:flex;gap:8px">
        <span class="abtn" style="flex:1;text-align:center;border-color:rgba(0,212,255,.55);color:var(--cyan)">DODGE — ROLL d4 <small style="display:block;font-size:8px;color:var(--muted)">needs 3+ · sidestep 1 hex</small></span>
        <span class="abtn" style="flex:1;text-align:center;border-color:rgba(168,85,247,.55);color:var(--purple)">TACTICAL ROLL <small style="display:block;font-size:8px;color:var(--muted)">declare a hex · forfeits movement</small></span>
        <span class="abtn" style="flex:1;text-align:center">BRACE <small style="display:block;font-size:8px;color:var(--muted)">halve it · hold the line</small></span>
        <span class="abtn" style="flex:1;text-align:center;color:var(--muted)">TAKE IT <small style="display:block;font-size:8px">4 CRUSH · torso</small></span></div>
      <div style="font-size:8px;color:var(--muted);margin-top:8px;letter-spacing:1px">
        ⛔ ITS NEXT INTENT IS THE VALVE BLAST — THE ICON SAYS UNDODGABLE BEFORE IT HAPPENS. MOVE OR EAT IT. (R26)</div></div>'''
    body = (bbar(rec="00:09:12", watching="4,388,020")
            + f'<div class="topstrip">{sel_imani_dodge()}<div class="topcenter">{shortcuts()}{tl}</div>{odds}</div>'
            + f'<div class="mid">{rail_party(active="imani-dodge")}'
            + world(den_board(cone=False), den_tokens("dodge"),
                    '<div class="phasetags">' + pill("p-fire", "PHASE 1") + pill("p-danger", "REACTION WINDOW") + "</div>")
            + f'<div class="rightcol">{right}{inspector_boss()}</div></div>'
            + ask
            + f'<div class="bottomstrip">{chat_panel()}{launcher("ready")}</div>'
            + ticker("“Four tons of reptile, one very small human decision. LOVE this table.”")
            + watermark("FRAME 3 · REACTION — R22 DODGE ASK + R26 UNDODGABLE"))
    return page("HUD v2 — the dodge ask", body)

# ---------------------------------------------------------------- frame 4 ----
def explore_board():
    svg_parts = [hexgrid(13, 7, 42, terrain={(4, 5), (5, 5)})]
    svg_parts.append(wall(300, 60, 260, 0))
    svg_parts.append(wall(680, 200, 170, 90))
    svg_parts.append(door(180, 470, 90, "open", 0))       # kennel gate (west exit)
    svg_parts.append(door(700, 420, 80, "closed", 90))    # service hatch (east exit)
    # cleared markers
    for (q, r) in ((5, 3), (7, 4)):
        cx, cy = hex_center(q, r, 42)
        svg_parts.append(f'<text x="{cx}" y="{cy+5}" text-anchor="middle" font-size="20" fill="#3a4560">✕</text>')
    # noise ripple at kennel door
    svg_parts.append('<g stroke="rgba(255,122,47,.5)" fill="none" stroke-width="1.4">'
                     '<circle cx="180" cy="470" r="26"/><circle cx="180" cy="470" r="44" stroke-opacity=".6"/>'
                     '<circle cx="180" cy="470" r="62" stroke-opacity=".3"/></g>')
    svg = f'<svg width="900" height="560" viewBox="0 0 900 560">{"".join(svg_parts)}</svg>'
    tags = ('<span class="groundtag" style="left:22%;top:84%;border-color:rgba(255,122,47,.6);color:var(--fire)">'
            '👂 BARKING · LOUD — 2 HOUNDS, HERDERS</span>'
            '<span class="groundtag" style="left:64%;top:60%;border-color:rgba(200,168,75,.5);color:var(--gold)">'
            'SERVICE HATCH · CREW ROUTE</span>'
            '<span class="groundtag" style="left:17%;top:92%;border-color:rgba(0,212,255,.3);color:var(--muted)">'
            'RUBBLE · DIFFICULT GROUND ×2</span>')
    return f'<div class="stage"><div class="board">{svg}</div></div>{tags}'

def explore_tokens():
    toks = [token(46, 60, "🛡", "IMANI", 95, "var(--success)", "ally-sel"),
            token(53, 70, "🎭", "DARIO", 88, "var(--gold)", "", (("🩸", "bleeding T1"),)),
            token(40, 72, "🃏", "SASHA", 84, "var(--success)", "", (), sub="JOINED AS-IS · L-ARM 1/2")]
    return "".join(toks)

def frame_explore():
    # Owner ruling 2026-08-19 (decision 8): exploration is FREE-FORM, not turn-based.
    # No clock, no Moment order, no ready/waits — the timing strip is replaced by a
    # route breadcrumb, and the clock only starts when contact does.
    tl = '''<div class="timeline" style="border-color:rgba(0,212,255,.35)">
      <span class="pill p-cyan">✦ OUT OF COMBAT</span>
      <span class="pill p-mute">FREE MOVEMENT — NO CLOCK</span>
      <div class="track" style="height:44px;margin-top:2px">
        <div class="rail-line" style="top:20px"></div>
        <span class="tl-band" style="left:0%;width:26%;top:19px;background:rgba(0,255,136,.65)"></span>
        <span class="tl-chip" style="left:11%;top:26px;border-color:rgba(0,255,136,.5);color:var(--success)">BROOD LANDING ✓</span>
        <span class="nowmark" style="left:26%;top:10px"></span>
        <span class="tl-chip" style="left:45%;top:26px;border-color:rgba(0,212,255,.5);color:var(--cyan)">⌖ YOU ARE HERE — 2 WAYS ON</span>
        <span class="tl-chip" style="left:83%;top:26px;border-color:var(--border);color:var(--muted)">THE DEN · BOTH ROUTES END HERE</span>
      </div>
      <span class="lbl" style="white-space:nowrap">clock starts on contact</span></div>'''
    odds = odds_panel(
        [("Survival odds", "2 : 1 ▲", "color:var(--success)"), ("Top bidder", "ENYO ×3.1", "color:var(--gold)"),
         ("Room record", "BROOD LANDING — CLEAR", "font-size:10px")],
        "HESTIA approves of the recruit · LOKI wants the kennel, loudly")
    right = f'''<div class="rpanel">
      <h4>Crowd <span class="pill p-gold" style="font-size:8px">HOLDS</span></h4>
      <div class="hypehead"><span class="v">68<small> / 100</small></span><span class="lbl">hype</span></div>
      <div class="hypebar"><i style="width:68%"></i></div>
      <div class="bandrow"><span class="band">ELECTRIC ⚡</span><span class="flag f-gold">HYPE CHAIN ARMED</span></div>
      <div class="goal"><div class="t">⛓ HYPE CHAIN — R29</div>
      <div class="d">Exploration is glue, not rest. The next room <b>opens at 40%</b> of your ending meter
      — <span class="mono" style="color:var(--gold)">68 → 27 head start</span>. Chain the den after and it keeps 60%.</div>
      <div class="r">{pill("p-gold","CHAINING IS REWARDED")}</div></div></div>'''
    inspector = f'''<div class="rpanel insp"><h4>Inspector — KENNEL GATE <span class="pill p-cyan" style="font-size:8px">OBJECT</span></h4>
      <div class="part"><span class="pn">STATE</span><span class="ph" style="color:var(--cyan)">OPEN</span></div>
      <div class="part"><span class="pn">LEADS TO</span><span class="ph">THE KENNEL GAUNTLET</span></div>
      <div class="part"><span class="pn">HEARD THROUGH IT</span><span class="ph" style="color:var(--fire)">BARKING · LOUD</span></div>
      <div class="part"><span class="pn">READ</span><span class="ph" style="color:var(--danger)">PACK · HERDERS · BLOOD-SCENT</span></div>
      <div class="knowrow">{flag("f-purple","ALERTED ≠ LOCATED — they heard the fight, not you")}{flag("","R20")}</div>
      <div class="telegraph" style="border-color:rgba(0,212,255,.4);background:rgba(0,212,255,.05)">
      <div class="t" style="color:var(--cyan)">⛭ CHOOSE THE ROUTE</div>
      <div class="d"><b>KENNEL GAUNTLET</b> — the hound pens. Elite pair, hunts as a pack, funnels prey into doors.
      Rich reward table.<br><b>SERVICE HATCH</b> — the crew corridor. Lighter fight, narrow ground,
      a locked supply cage (simple lock · 1 MOMENT pick).</div></div></div>'''
    launcher_exp = f'''<div class="launcher"><div class="whoclock"><span class="w">FREE MOVEMENT</span>
      <span class="n">PARTY WALKS TOGETHER</span></div>
      <span class="abtn">↔ WALK <b class="fa-count">FREE</b></span><span class="abtn open">INTERACT</span>
      <span class="abtn">SKILLS <b class="fa-count">OUT-OF-COMBAT ONLY</b></span><span class="abtn">INVENTORY</span>
      <span class="endturn" style="border-color:rgba(0,212,255,.55);background:rgba(0,212,255,.07)">ENTER ▸ KENNEL</span>
      <div class="conseq">No turn to end — walk freely until you <b>enter</b>. ENTER → locks the route ·
      <b>hype chain opens the fight at 27</b> · wounds persist · <span class="to">the clock starts</span></div>
      <div class="flyout" style="left:270px;border-color:rgba(0,212,255,.4)">
        <div class="fly-h">INTERACT</div>
        <div class="frow sel"><span class="fn">KENNEL GATE <small>enter the gauntlet — the pack is AWAKE</small></span><span class="fc">EXIT</span></div>
        <div class="frow"><span class="fn">SERVICE HATCH <small>the crew route — quieter, tighter</small></span><span class="fc">EXIT</span></div>
        <div class="frow"><span class="fn">SASHA — VOICEBOX <small>throw a bark down the corridor · mobs investigate THE SOUND</small></span><span class="fc">FREE</span></div>
        <div class="frow"><span class="fn">SCOUT AHEAD <small>walk the party up without entering — the gate does not close behind you</small></span><span class="fc">FREE</span></div>
      </div></div>'''
    body = (bbar(rec="00:05:30", watching="3,981,554")
            + f'''<div class="topstrip"><div class="selpanel"><span class="selglyph">🃏</span><div class="selbody">
              <div class="selname">SASHA “LITTLE SHADOW” <small>JOINED AS-IS — CARRIES HER FIGHT</small></div>
              <div class="selrow">{pill("p-mute","⚜ UNSIGNED — gods circling")}{pill("p-danger","L-ARM 1/2")}{pill("p-purple","MIND 5")}</div>
              <div class="selrow">{pill("p-gold","📸 CAMERA ×1")}{flag("f-cyan","NEW RECRUIT")}{flag("f-success","FREE TO WALK — NO MOMENT COST")}</div>
              </div></div><div class="topcenter">{shortcuts()}{tl}</div>{odds}</div>'''
            + f'<div class="mid">{rail_party(active="none", sasha_state="SELECTED")}'
            + world(explore_board(), explore_tokens(),
                    '<div class="phasetags">' + pill("p-cyan", "BROOD LANDING — CLEAR") + pill("p-success", "✦ FREE MOVEMENT — NO CLOCK RUNNING") + "</div>")
            + f'<div class="rightcol">{right}{inspector}</div></div>'
            + f'<div class="bottomstrip">{chat_panel()}{launcher_exp}</div>'
            + ticker("“Nobody is on a clock. Take your time. The hounds certainly are not going anywhere.”")
            + watermark("FRAME 4 · MODE A — FREE-FORM EXPLORATION · R29 ROOM GRAPH"))
    return page("HUD v2 — Mode A (exploration)", body)

# ---------------------------------------------------------------- frame 5 ----
def frame_modcenter():
    offer_rail = ""
    offers = [
        ("THE UNSEEN", "CAMOUFLAGE 5 + NIGHTLURKING 3", "infiltration", False),
        ("THE LONG CON", "FEINT 5 + VIBE CONTROL 3", "performance", True),
        ("PHANTOM GRASP", "TELEKINESIS 5 + PRESSURE HOLD 3", "control", False),
    ]
    for name, par, grp, sel in offers:
        cls = "border:1px solid rgba(200,168,75,.6);background:rgba(200,168,75,.07)" if sel \
              else "border:1px solid var(--border)"
        offer_rail += (f'<div style="{cls};border-radius:7px;padding:10px 12px;flex:1">'
                       f'<div style="font-size:12px;font-weight:900;letter-spacing:1px;color:{"var(--gold)" if sel else "#dfeaff"}">{name}</div>'
                       f'<div class="lbl" style="margin-top:3px;letter-spacing:1px">{par}</div>'
                       f'<div style="margin-top:6px">{flag("f-purple","BROAD-ONLY · " + grp.upper())}{flag("f-gold","BLESSED")}</div></div>')
    popup = f'''<div class="popup">
      <div style="display:flex;align-items:center;gap:12px;padding:13px 18px;border-bottom:1px solid var(--border);background:var(--panel2)">
        <span style="font-size:16px;font-weight:900;letter-spacing:4px;color:var(--gold);text-shadow:0 0 18px rgba(200,168,75,.6)">⬡ MODIFICATION CENTER</span>
        <span class="pill p-gold">SPECIAL OFFERS — THE HOUSE MAKES THREE</span>
        <span style="margin-left:auto" class="pill p-purple">⏸ PAUSED</span>
        <span class="pill p-mute">ESC CLOSES</span></div>
      <div style="display:flex;gap:10px;padding:14px 18px">{offer_rail}</div>
      <div style="display:flex;gap:16px;padding:0 18px 16px">
        <div style="flex:1.3;border:1px solid rgba(200,168,75,.4);border-radius:8px;padding:14px 16px;background:rgba(200,168,75,.04)">
          <div style="font-size:19px;font-weight:900;letter-spacing:2px;color:var(--gold)">THE LONG CON</div>
          <div style="font-size:10px;color:var(--text);line-height:1.7;margin:7px 0">The combat misdirection and the
            crowd's mood, fused into one sustained deception — <i>the fight you show them was never the fight you
            were having.</i> Project the con at everyone watching you; their next move against you fumbles, and
            every fumble is a free step. The deception <b style="color:var(--gold)">pays the crowd while it holds</b>.</div>
          <div class="knowrow">{flag("f-gold","TIER 2 — GEMSTONE MERGE")}{flag("f-danger","CONSUMES BOTH PARENTS")}{flag("","ARRIVES AT L1 · CAP 5")}{flag("f-cyan","OPTIONAL — PARENTS CAP AT 5 ANYWAY")}{flag("f-purple","NAME PROVISIONAL")}</div>
        </div>
        <div style="flex:1;display:flex;flex-direction:column;gap:8px">
          <div class="lbl">requirements — DARIO</div>
          <div class="part"><span class="pn">FEINT — identity parent</span><span class="ph" style="color:var(--gold)">3 / 5</span><span class="st" style="border-color:rgba(200,168,75,.5);color:var(--gold)">IN PROGRESS</span></div>
          <div class="part"><span class="pn">VIBE CONTROL — secondary</span><span class="ph" style="color:var(--muted)">— / 3</span><span class="st">NOT LEARNED</span></div>
          <div class="part"><span class="pn">PRICE</span><span class="ph" style="color:var(--purple)">KAN-7 — TBD</span><span class="st" style="border-color:rgba(168,85,247,.5);color:var(--purple)">LOUNGE ECONOMY</span></div>
          <div style="border:1px solid var(--border);border-radius:6px;padding:9px 11px;font-size:9px;color:var(--muted);line-height:1.7">
            An offer is the recorded GM call on a broad-only pair — <b style="color:var(--text)">offered, never automatic</b>.
            Parents stop at 5 either way (unless that skill was always linear); declining costs you nothing but
            the ceiling. Tier-3 merges exist. The house is patient.</div>
          <span class="abtn" style="text-align:center;opacity:.5;border-color:var(--border)">NOT YET — 2 REQUIREMENTS SHORT</span>
        </div></div></div>'''
    body = (bbar(rec="00:11:04", watching="4,020,910")
            + f'''<div class="topstrip"><div class="selpanel"><span class="selglyph">🎭</span><div class="selbody">
              <div class="selname">DARIO “ENCORE” <small>AT THE MOD-CENTER COUNTER</small></div>
              <div class="selrow">{pill("p-gold","⚜ ENYO")}{pill("p-mute","LOUNGE — BETWEEN ROOMS")}</div>
              </div></div><div class="topcenter">{shortcuts(active=None)}
              {timeline(chips=[(3.0,"LOUNGE — CLOCKS HOLD","p-mute")],bands=[],now=3.0)}</div>
              {odds_panel([("Survival odds","2 : 1",""),("Top bidder","ENYO ×3.1","color:var(--gold)")],
                          "The gods can see the shop. ENYO thinks the con suits him.")}</div>'''
            + f'<div class="mid">{rail_party(active="none")}'
            + world(explore_board(), explore_tokens())
            + '</div>'
            + '<div class="dim"></div>' + popup
            + f'<div class="bottomstrip">{chat_panel()}{launcher("ready")}</div>'
            + ticker("“Retail therapy, contestant edition. He cannot afford it. He is going to look anyway.”")
            + watermark("FRAME 5 · MODE D — POPUP · MOD-CENTER TIER-2 OFFERS"))
    return page("HUD v2 — Mode D (Mod-Center)", body)

# -------------------------------------------------------------------- main ---
FRAMES = {
    "hud-ready.html": frame_ready,
    "hud-targeting.html": frame_targeting,
    "hud-dodge-ask.html": frame_dodge,
    "explore-branch.html": frame_explore,
    "mod-center.html": frame_modcenter,
}

if __name__ == "__main__":
    for fname, fn in FRAMES.items():
        with open(os.path.join(OUT, fname), "w") as f:
            f.write(fn())
        print("wrote", fname)
