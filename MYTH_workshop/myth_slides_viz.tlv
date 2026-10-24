\m4_TLV_version 1d: tl-x.org
\SV
   // Live Doc: Animated copies of "MYTH Workshop for Makerchip" slides, driven by the reference-solution models.
   // The solutions instantiate the library (/myth_lib, below) and the slide macro for the lab being built.
   // Each slide macro draws its full slide (a page of the deck) and animates it with chips (values on wires)
   // and highlights (colored, once decoded, by instruction type). The slides' red delta (the change from the prior
   // lab) is muted to maroon, leaving the highlight colors distinct.


// Library of shared VIZ functions. Instantiate as /myth_lib under /_top. Each function takes the calling
// \viz_js context (`viz`).
\TLV myth_slides_lib(/_top)
   \viz_js
      box: {width: 10, height: 10, strokeWidth: 0},
      lib: {
         slidesUrl: "https://raw.githubusercontent.com/rweda/Makerchip-public/main/courses/MYTH%20Slides.pdf",
         // Build the full slide on PDF page `page` (box: 720x405). `build` is extractToFabric's build option.
         // Any element role named "hidden" is hidden.
         slide(viz, page, build) {
            const Rect = viz.getFabric().Rect
            return viz.global.pdf.extractToFabric(viz, this.slidesUrl, {
               extract: {page, text: "all", imageData: true, select: {mode: "region", rect: [0, 0, 720, 405]}},
               build: {...build, notice: false, onReady: (ready) => {
                  for (const p of ready.parts) {
                     if (p.stroke === "#ff0000") p.set({stroke: "#7a1f2b"})
                     if (p.fill === "#ff0000") p.set({fill: "#7a1f2b"})
                     for (const st of Object.values(p.styles ?? {}).flatMap(Object.values)) if (st.fill === "#ff0000") st.fill = "#7a1f2b"
                     // Furniture (e.g. the title banner) can overhang the page; clip just those paths to it.
                     // (A clipPath forces Fabric to cache the object as a bitmap, so not the group. See mono issue 031.)
                     // A clipPath is relative to the object's center.
                     if (p.type === "path" && (p.left < -1 || p.top < -1 || p.left + p.width > 721 || p.top + p.height > 406))
                        p.clipPath = new Rect({left: -p.left - p.width / 2, top: -p.top - p.height / 2, width: 720, height: 405})
                  }
                  for (const o of [].concat(ready.elements.hidden ?? [])) o.set({visible: false})
                  build.onReady?.(ready)
               }},
            })
         },
         // Highlight (or restore) element(s) `objs` with Fabric `props` (or `on`, if an object), by default, a stroke (or,
         // for fill-only elements, fill) of palette `pal` ([stroke, fill], default blue).
         hi(objs, on, props, pal = this.types.r) {
            for (const o of [].concat(objs ?? [])) {
               o.orig ??= {stroke: o.stroke, strokeWidth: o.strokeWidth, fill: o.fill}
               o.set({...o.orig, ...on && (typeof on === "object" ? on : props ?? (o.orig.stroke ? {stroke: pal[0], strokeWidth: 2} : {fill: pal[1]}))})
            }
         },
         // Highlight palettes by RISC-V instruction type (format), and the decoded type of the instruction in @k. typeAt: the
         // stage of the instruction whose type colors each unstaged role (by default, for the pipelined slides; a page cfg's
         // typeAt overrides).
         types: {r: ["#0277bd", "#b3e5fc"], i: ["#2e7d32", "#c8e6c9"], s: ["#ef6c00", "#ffe0b2"], b: ["#6a1b9a", "#e1bee7"],
                 u: ["#00838f", "#b2ebf2"], j: ["#ad1457", "#f8bbd0"]},
         typeAt: {tgt_loop: 3, inc_loop: 1, rf_loop: 4, bypass: 3, bypass1: 3, bypass2: 3, ld_loop: 3, ldst: 3, alu_wr: 3,
                  ld_wr: 5, wr_mux: 3, st_data: 4, dmem: 4, jalr: 3, br: 3, br1: 4, br2: 5},
         // typeAt for the single-cycle slides.
         seqAt: {tgt_loop: 1, inc_loop: 1, rf_loop: 2},
         typeOf(s, k) {
            return Object.keys(this.types).find((t) => s("is_" + t + "_instr", k)?.asBool())
         },
         // A value chip at (left, top), centered, or left-aligned at left.
         chip(viz, left, top, align = "center") {
            return new (viz.getFabric().Text)("", {left, top, originX: align, originY: "center",
               fontSize: 11, fontFamily: "monospace", fill: "#1565c0", backgroundColor: "white", opacity: 0.9})
         },
         // Init for a slide of one or more PDF pages, stacked vertically. cfgs: a page cfg or an array of them:
         // {page, primitives/labels (element roles), chips: {key: [left, top, prefix]}, marks: {key: f},
         //  stages: [[label, left, top] (by stage)], bounds: [x (between stages)], split: {primitive: stage}, ...}
         // (Chip keys and mark functions are interpreted by the render function. Marks are highlight rects. Stages are
         // pipestage labels (giving roles "stage<n>"; null if none) and positions of the overlays naming each stage's
         // instruction (sparse for stages not shown; their bounds are -Infinity).
         // Split primitives (non-vertical lines, by the stage their role's lit refers to) are cut at the stage bounds, and
         // each piece is lit with signal references shifted to the instruction in the piece's stage. Roles in `staged`
         // (role: lit, as in cpuRender) are lit relative to each primitive's own stage (at its center), as stage 0; their
         // lines are split (`at: {primitive: stage}` overrides a staged primitive's stage). `cuts: {primitive: [x, role]}`
         // also cuts a line at x (or y, if vertical), lighting the part beyond as `role` (staged or not). A primitive may
         // have a list of cuts. A cut polyline (e.g. a loop drawn as a rect) is cut into its segments, and a cut
         // [x, y, role] cuts only the segment(s) through (x, y).)
         init(viz, cfgs) {
            const {Rect, Text, Path} = viz.getFabric()
            viz._pages = [].concat(cfgs ?? []).map((cfg, i) => {
               const elementsAs = "liveDocElements" + (i || "")
               const labels = {...cfg.labels, ...Object.fromEntries((cfg.stages ?? []).flatMap(([t], k) => t == null ? [] : [["stage" + k, [t]]]))}
               const pieces = [], twins = [], stageAt = (x) => cfg.bounds.filter((b) => b < x).length
               const split = ({group, elements, parts}) => {
                  // Box fills (fill-only primitives) paired with their outlines (stroke-only, of the same shape).
                  const shape = (p) => [p.left, p.top, p.width, p.height].map(Math.round).join()
                  const opaque = (c) => c && !/^rgba\(.*, ?0\)$/.test(c)
                  const outlines = new Map(parts.filter((p) => p.stroke && !opaque(p.fill)).map((p) => [shape(p), p]))
                  for (const p of parts) if (!p.stroke && opaque(p.fill) && outlines.has(shape(p))) twins.push([p, outlines.get(shape(p))])
                  for (const role in cfg.primitives) [].concat(cfg.primitives[role]).forEach((idx, j) => {
                     const cut = cfg.cuts?.[idx], o = [].concat(elements[role])[j], ref = cfg.split?.[idx]
                     if (!cfg.staged?.[role] && ref == null && !cut) return
                     // A piece at x, lit as role r: staged roles relative to the piece's stage, split primitives shifted from
                     // their ref stage, others unshifted. `stage`: the stage of the instruction it carries (for its color).
                     const piece = (obj, r, x) => {
                        const stage = cfg.staged?.[r] ? cfg.at?.[idx] ?? stageAt(x) : ref == null ? null : stageAt(x)
                        pieces.push({obj, lit: cfg.staged?.[r] ?? cfg.lit[r], stage, delta: cfg.staged?.[r] ? stage : ref == null ? 0 : stage - ref})
                     }
                     const px = o.path.flatMap((c) => c.slice(1).filter((v, k) => k % 2 === 0))
                     const cx = (Math.min(...px) + Math.max(...px)) / 2
                     // The vertices of a line, or of a cut polyline.
                     const crosses = cfg.bounds.some((b) => Math.min(...px) < b && b < Math.max(...px))
                     const vs = o.path.every(([c]) => "MLZz".includes(c)) && (o.path.length === 2 || cut || cfg.staged?.[role] && crosses) &&
                        o.path.map(([c, ...xy]) => "Zz".includes(c) ? o.path[0].slice(1) : xy)
                     if (!vs) {
                        if (!cfg.staged?.[role]) throw new Error("Split primitive " + idx + " is not a line.")
                        return piece(o, role, cx)
                     }
                     const cs = (typeof cut?.[0] === "object" ? cut : cut ? [cut] : []).map((c) => c.length === 3 ? c : [c[0], null, c[1]])
                     const objs = []
                     for (let k = 1; k < vs.length; k++) {
                        const [[x0, y0], [x1, y1]] = [vs[k - 1], vs[k]], horiz = x0 !== x1
                        if (!horiz && ref != null) throw new Error("Split primitive " + idx + " is vertical.")
                        const pt = (t) => horiz ? [t, y0 + (y1 - y0) * (t - x0) / (x1 - x0)] : [x0, t]
                        // Cut positions along the segment (x, or y if vertical), and the role beyond each.
                        const [a0, a1] = horiz ? [x0, x1] : [y0, y1], within = (b) => (b - a0) * (b - a1) < 0
                        const ats = cs.flatMap(([x, y, r]) => {
                           const at = horiz ? x : y ?? x
                           return within(at) && (y == null || Math.abs(horiz ? pt(x)[1] - y : x0 - x) < 1) ? [[at, r]] : []
                        }).sort((a, b) => a[0] - b[0])
                        const ts = [a0, a1, ...(horiz ? cfg.bounds : []).filter(within), ...ats.map(([at]) => at)].sort((a, b) => a - b)
                        for (let n = 1; n < ts.length; n++)
                           objs.push([pt(ts[n - 1]), pt(ts[n]), ats.findLast(([at]) => ts[n] > at)?.[1] ?? role])
                     }
                     if (objs.length === 1) return piece(o, role, cx)
                     const {type, version, path, left, top, width, height, ...style} = o.toObject()
                     for (const [p0, p1, r] of objs) {
                        const obj = new Path([["M", ...p0], ["L", ...p1]], style)
                        group.insertAt(obj, group.getObjects().indexOf(o))
                        piece(obj, r, (p0[0] + p1[0]) / 2)
                     }
                     o.set({visible: false})
                  })
               }
               const fig = this.slide(viz, cfg.page, {primitives: cfg.primitives, labels, elementsAs, onReady: split})
               fig.set({top: 420 * i})
               fig.add(new Rect({width: 720, height: 405, fill: "", stroke: "black", strokeWidth: 0.75}))
               const chips = {}, marks = {}
               for (const key in cfg.marks) fig.add(marks[key] = new Rect({fill: "rgba(2,119,189,0.15)", stroke: "#0277bd", strokeWidth: 2, visible: false}))
               for (const key in cfg.chips) { const [l, t, , , , a] = cfg.chips[key]; fig.add(chips[key] = this.chip(viz, l, t, a)) }
               const stages = (cfg.stages ?? []).map(([, left, top]) => new Text("", {left, top, originX: "center", originY: "center",
                  fontSize: 9, fontFamily: "monospace", fontWeight: "bold", backgroundColor: "rgba(255,255,255,0.8)"}))
               stages.forEach((o) => fig.add(o))
               return {cfg, fig, chips, marks, stages, pieces, twins, elementsAs}
            })
            return Object.fromEntries(viz._pages.map((p, i) => ["fig" + i, p.fig]))
         },
         // staged for the calculator slides (rendered by cpuRender, with pipe "calc"; each primitive lit for the transaction in
         // its stage, as for the CPU), for $op[`bits`-1:0]:
         //   always: lit always; run: when not in reset; val: the operand and $op wires, when calculating (neither resetting
         //   nor invalid); op<i>: operator i's operand wires, box, and output, when selected and calculating; reset_path: by
         //   $reset; zero_path: when resetting or invalid; invalid_path: when !$valid; active: when $reset || $valid; hold:
         //   ($mem's hold path) when calculating, but not $op 5 (mem).
         // (Loops outside the pipeline are unstaged, in `lit`, e.g. lib.calcLoop.)
         calcStaged(bits = 2) {
            const reset = (s) => s("reset", 0)?.asBool(), calc = (s) => this.valid(s, 0) && !reset(s)
            const op = (s) => s("op", 0)?.asInt() & ((1 << bits) - 1)
            return {always: () => true, run: (s) => !reset(s), val: calc, reset_path: reset, zero_path: (s) => !calc(s),
                    invalid_path: (s) => s("valid", 0)?.asBool() === false, active: (s) => reset(s) || s("valid", 0)?.asBool() !== false,
                    hold: (s) => calc(s) && op(s) !== 5, ...Object.fromEntries([...Array(1 << bits).keys()].map((i) => ["op" + i, (s) => calc(s) && op(s) === i]))}
         },
         // lit for the calculator's loop of $out back to $val1 (outside the pipeline), when @1 calculates.
         calcLoop: {loop: (s) => !s("reset", 1)?.asBool() && s("valid", 1)?.asBool() !== false},
         // RISC-V slides: init for the last lab slide at or before `slide`.
         // (A cpuSlides entry may be a function of the library, returning the cfg(s).)
         cpuInit(viz, slide) {
            const cfg = this.cpuSlides[Math.max(...Object.keys(this.cpuSlides).filter((n) => n <= slide))]
            return this.init(viz, typeof cfg === "function" ? cfg(this) : cfg)
         },
         // Page cfg for the register-file diagram slides, whose rf box is offset `dy` from that of slide 20.
         // Wires light when enabled. rd/wr: stages.
         rfCfg(page, dy, rd = 1, wr = 1) {
            const c = (name, stage, x, y) => [name + "@" + stage, [x, y + dy]]
            return {page,
               chips: Object.fromEntries([c("rf_wr_en", wr, 512, 188), c("rf_wr_index", wr, 512, 206), c("rf_wr_data", wr, 512, 225),
                  c("rf_rd_en1", rd, 512, 243), c("rf_rd_index1", rd, 512, 261), c("rf_rd_en2", rd, 512, 278), c("rf_rd_index2", rd, 512, 296),
                  c("rf_rd_data1", rd, 558, 215), c("rf_rd_data2", rd, 558, 237)]),
               primitives: {wr: [13, 15, 17, 19], rd1: [21, 23, 26], rd2: [34, 36, 29]},
               typeAt: {wr: wr, rd1: rd, rd2: rd},
               lit: {wr: (s) => s("rf_wr_en", wr)?.asBool(), rd1: (s) => s("rf_rd_en1", rd)?.asBool(), rd2: (s) => s("rf_rd_en2", rd)?.asBool()}}
         },
         // lit for the pipelined (RF read @2, write @3) slides with the 3-cycle $valid: the PC mux's >>3 inputs (not in
         // reset; >>3$inc_pc only from a valid instruction), the RF write's output loop (from @4, the written value having
         // reached the RF), and the >>3$valid loop.
         pipeLit: {
            tgt_loop: (s) => !s("reset", 1)?.asBool() && s("valid_taken_br", 3)?.asBool(),
            inc_loop: (s) => !s("reset", 1)?.asBool() && s("valid_taken_br", 3)?.asBool() === false && s("valid", 3)?.asBool(),
            rf_loop: (s) => s("rf_wr_en", 4)?.asBool(),
            valid_loop: (s) => s("valid", 0).asBool() && !s("start", 0).asBool(), valid_mux: (s) => s("valid", 0).asBool()},
         // lit for the single-cycle slides (logic @1): the PC's reset input, the PC (mux and output, always active), its +1
         // loop, or, with `br`, its branch-target loop (lit when taken), and the RF write's output loop (from @2, the written
         // value having reached the RF), for valid instructions ($rf_wr_en is not gated by $valid until slide 36).
         seqLit(br) {
            const reset = (s) => s("reset", 1)?.asBool(), taken = (s) => br && s("taken_br", 1)?.asBool()
            return {reset, pc: () => true, inc_loop: (s) => !reset(s) && !taken(s), tgt_loop: (s) => !reset(s) && taken(s),
                    rf_loop: (s) => this.valid(s, 2) && s("rf_wr_en", 2)?.asBool()}
         },
         // staged for the pipelined (and single-cycle) slides (lit in the color of their instruction's type, once decoded,
         // from @1):
         //   datapath: the wires and boxes of each stage, lit while that stage holds a valid instruction;
         //   br_add/br_cmp: the branch target adder and comparator, for instructions using them;
         //   rd<i>_out: the RF read outputs (cut from datapath), lit when read, or grayed when bypassed (if `byp`);
         //   src<i>: the source muxes and ALU inputs, lit when read;
         //   alu: the ALU (and its output), for instructions writing the RF or accessing DMem;
         //   mem: DMem, for loads and stores;
         //   rf_wr: the RF write, for valid instructions ($rf_wr_en is not gated by $valid until slide 36) or load data;
         //   inc: the +1 box (and output), when its result is used.
         pipeStaged(byp = true) {
            const v = (s) => this.valid(s, 0), is = (s, ...ops) => ops.some((op) => s("is_" + op, 0)?.asBool())
            const src = (i) => (s) => v(s) && s("rf_rd_en" + i, 0)?.asBool()
            const rd = (i) => (s) => src(i)(s) && (!byp || !this.bypass(s, i, 0) || {stroke: "#b7b7b7"})
            return {datapath: v, br_add: (s) => v(s) && is(s, "b_instr", "jal"), br_cmp: (s) => v(s) && is(s, "b_instr"),
                    rd1_out: rd(1), rd2_out: rd(2), src1: src(1), src2: src(2),
                    alu: (s) => v(s) && (s("rf_wr_en", 0)?.asBool() || is(s, "load", "s_instr")),
                    mem: (s) => v(s) && is(s, "load", "s_instr"),
                    rf_wr: (s) => s("rf_wr_en", 0)?.asBool() && (v(s) || s("valid_load", 2)?.asBool()), inc: (s) => this.incUsed(s, 0)}
         },
         // Whether the instruction in @k is valid (by $valid, or, before $valid exists, not in reset).
         valid(s, k) {
            return s("valid", k)?.asBool() ?? !s("reset", k)?.asBool()
         },
         // Whether the instruction in @k uses its incremented PC: valid, and not redirecting (by a taken branch or jump).
         incUsed(s, k) {
            return this.valid(s, k) && !s("valid_taken_br", k)?.asBool() && !s("valid_jump", k)?.asBool()
         },
         // Whether source i (1 or 2) of the instruction in @at bypasses the previous instruction's RF write.
         bypass(s, i, at = 2) {
            return s("valid", at)?.asBool() && s("rf_rd_en" + i, at)?.asBool() && s("rf_wr_en", at + 1)?.asBool() &&
                   s("rf_wr_index", at + 1).asInt() === s("rf_rd_index" + i, at).asInt()
         },
         // The test program's instruction at byte address `pc` (from cpu_viz), with decimal immediates, or "".
         asm(viz, pc) {
            const str = pc == null ? null : viz.sigRef("|cpuviz/imem[" + pc / 4 + "]$instr_str", 2)?.asString()
            return str?.replace(/^\(.\) /, "").trim()
               .replace(/,([01]+)$/, (m, b) => "," + (parseInt(b, 2) - (b.length >= 12 && b[0] === "1" ? 2 ** b.length : 0))) ?? ""
         },
         // Value chips on the datapath wires of the pipelined slides with bypass muxes (slide 39's layout).
         pipeChips: {"pc@1": [210, 124], "src1_value@3": [437, 146, "", undefined, "rf_rd_en1"], "src2_value@3": [437, 196, "", undefined, "rf_rd_en2"], "result@3": [479, 164]},
         // RISC-V slides (render). Page cfgs (in cpuSlides) also have:
         // {chips: {"signal@stage": [left, top, prefix, fmt, en, align]}, lit/staged: {role: (s) => bool or hi props},
         //  marks: {key: (s) => [left, top, width, height] or null}},
         // where s(signal, stage) is the |cpu SignalValue for the transaction in that stage (null if nonexistent).
         // (A signal may be scoped, e.g. "/xreg[10]$value".)
         // Chips show fmt(SignalValue) (default: hex), or "-" if $<signal>_valid exists and is false, grayed if the stage's
         // instruction is invalid or its signal `en` is false (for unscoped signals).
         // Roles not in `lit` are static (e.g. hidden). Each stage's instruction and label are grayed when invalid (else, once
         // decoded, the instruction is in its type's color).
         cpuRender(viz) {
            const s = (name, stage) => viz.sigRef("|" + (viz._pages[0].cfg.pipe ?? "cpu") + (name[0] === "/" ? "" : "$") + name, 2 * stage)
            for (const {cfg, chips, marks, stages, pieces, twins, elementsAs} of viz._pages) {
               const el = viz[elementsAs]
               if (!el) continue
               for (const key in chips) {
                  const [name, stage] = key.split("@"), [, , prefix = "", fmt = (v) => v.asInt(null)?.toString(16) ?? "?", en] = cfg.chips[key]
                  const v = s(name, +stage), dim = name[0] !== "/" && ["valid", en].some((e) => e && s(e, +stage)?.asBool() === false)
                  chips[key].set({text: prefix + (s(name + "_valid", +stage)?.asBool() === false ? "-" : v ? fmt(v) : "?"),
                                  fill: dim ? "#aaa" : "#1565c0"})
               }
               // Lit in the palette of the type of the instruction in @k (the role's, by typeAt, or the piece's), once decoded.
               const at = {...this.typeAt, ...cfg.typeAt}, pal = (k) => k >= 1 && this.types[this.typeOf(s, k)] || undefined
               for (const role in cfg.lit) this.hi(el[role], cfg.lit[role](s), undefined, pal(at[role]))
               for (const {obj, lit, stage, delta} of pieces) this.hi(obj, lit((name, k) => s(name, k + delta)), undefined, pal(stage))
               // Box fills light only with their outlines, in the outline's palette.
               for (const [f, o] of twins) {
                  f.orig ??= {stroke: f.stroke, strokeWidth: f.strokeWidth, fill: f.fill}
                  const p = o.orig && o.stroke !== o.orig.stroke && Object.values(this.types).find(([c]) => c === o.stroke)
                  f.set({fill: p ? p[1] : f.orig.fill})
               }
               for (const key in marks) {
                  const r = cfg.marks[key](s)
                  marks[key].set(r ? {left: r[0], top: r[1], width: r[2], height: r[3], visible: true} : {visible: false})
               }
               stages.forEach((o, k) => {
                  const invalid = !this.valid(s, k)
                  o.set({text: this.asm(viz, s("pc", k)?.asInt(null)), fill: invalid ? "#aaa" : k >= 1 && this.types[this.typeOf(s, k)]?.[0] || "#1565c0"})
                  this.hi(el["stage" + k], invalid, {fill: "#aaa"})
               })
            }
         },
         // RISC-V slide page cfgs, by lab slide number (printed). (PDF page = printed + 43, roughly.)
         cpuSlides: {
            // Fetch (part 1). (Only the PC is connected.)
            7: {page: 50,
               primitives: {pc_loop: [27, 29, 49, 51, 45]},
               chips: {"pc@0": [118, 205, "pc="]},
               stages: [[null, 116, 294]],
               lit: {pc_loop: (s) => !s("reset", 0).asBool()}},
            // Fetch (part 2).
            8: {page: 51,
               primitives: {pc_loop: [21, 23, 37, 39, 33], imem: [50], rd_en: [48]},
               chips: {"pc@0": [105, 148], "reset@0": [96, 262], "instr@1": [190, 218]},
               stages: [[null, 100, 312], [null, 226, 312]],
               lit: {pc_loop: (s) => !s("reset", 0).asBool(), imem: (s) => s("imem_rd_en", 1).asBool(), rd_en: (s) => s("imem_rd_en", 1).asBool()}},
            // Instruction types and immediate decode: the type-table cell for instr[6:2] and the active immediate format.
            10: [{page: 53,
                  chips: {"instr@1": [560, 95, "instr="]},
                  marks: {cell: (s) => { const op = s("instr", 1)?.asInt(null); if (op == null) return null
                     return [155 + 65 * ((op >> 2) & 7), 164 + 27.75 * ((op >> 5) & 3), 65, 27.75] }}},
                 {page: 54,
                  chips: {"imm@1": [620, 320, "imm="]},
                  marks: {row: (s) => { const i = ["i", "s", "b", "u", "j"].findIndex((t) => s("is_" + t + "_instr", 1)?.asBool())
                     return i < 0 ? null : [93, 139 + 31 * i, 552, 21] }}}],
            // Instruction fields (in the format table's R-type columns) and the instruction's format row.
            11: {page: 55,
               chips: {"funct7@1": [160, 300, "funct7="], "rs2@1": [267, 300, "rs2="], "rs1@1": [345, 300, "rs1="],
                       "funct3@1": [405, 300, "funct3="], "rd@1": [480, 300, "rd="], "opcode@1": [553, 300, "op="]},
               marks: {row: (s) => { const i = ["r", "i", "s", "b", "u", "j"].findIndex((t) => s("is_" + t + "_instr", 1)?.asBool())
                  return i < 0 ? null : [97, 130 + 27.6 * i, 483, 20] }}},
            // Same, with field validity.
            12: {page: 56,
               chips: {"funct7@1": [187, 277, "funct7="], "rs2@1": [280, 277, "rs2="], "rs1@1": [349, 277, "rs1="],
                       "funct3@1": [401, 277, "funct3="], "rd@1": [466, 277, "rd="], "opcode@1": [530, 277, "op="]},
               marks: {row: (s) => { const i = ["r", "i", "s", "b", "u", "j"].findIndex((t) => s("is_" + t + "_instr", 1)?.asBool())
                  return i < 0 ? null : [131, 129 + 24.2 * i, 423, 18] }}},
            // Instruction decode: the decoded instruction's row.
            13: {page: 57,
               chips: {"dec_bits@1": [645, 163, "", (v) => { const b = v.asBinaryStr("?"); return b[0] + "_" + b.slice(1, 4) + "_" + b.slice(4) }]},
               marks: {row: (s) => {
                  const rows = {beq: [58, 172], bne: [58, 186], blt: [58, 199], bge: [58, 213], bltu: [58, 226], bgeu: [58, 240],
                                addi: [58, 355], add: [270, 241]}
                  const op = Object.keys(rows).find((op) => s("is_" + op, 1)?.asBool())
                  return op && [rows[op][0], rows[op][1] - 7, op === "add" ? 170 : 182, 14] }}},
            // Register file read.
            16: (lib) => lib.rfCfg(59, 24),
            // Register file read (part 2): source values. (This and the other single-cycle datapath slides light the model
            // built so far: see seqLit and pipeStaged.)
            17: (lib) => ({page: 60,
               primitives: {pc: [51, 52, 26, 32], datapath: [35, 36, 49, 50, 39, 40, 34, 24], inc_loop: [46, 48, 42, 37, 38, 28], reset: [44, 30],
                            src1: [22]},
               chips: {"src1_value@1": [412, 120, "", undefined, "rf_rd_en1"], "src2_value@1": [408, 220, "", undefined, "rf_rd_en2"]},
               stages: [[1, 149, 288], [2, 323, 288]], bounds: [206], cuts: {28: [140, "pc"], 24: [277, "src2"]},
               typeAt: lib.seqAt,
               lit: lib.seqLit(false), staged: lib.pipeStaged(false)}),
            // ALU: sources, result, and the code for the instruction.
            18: (lib) => ({page: 61,
               primitives: {pc: [59, 60, 32, 38], datapath: [43, 44, 57, 58, 47, 48, 40, 30], inc_loop: [54, 56, 50, 45, 46, 34], reset: [52, 36],
                            src1: [28], alu: [41, 42, 20]},
               chips: {"src1_value@1": [402, 130, "", undefined, "rf_rd_en1"], "src2_value@1": [402, 227, "", undefined, "rf_rd_en2"], "result@1": [493, 212]},
               stages: [[1, 100, 297], [2, 293, 297]], bounds: [176], cuts: {34: [150, "pc"], 30: [248, "src2"]},
               marks: {code: (s) => s("is_addi", 1)?.asBool() ? [168, 319, 232, 15] : s("is_add", 1)?.asBool() ? [168, 334, 30, 14] : null},
               typeAt: lib.seqAt,
               // (The RF isn't written yet, so the ALU is lit for instructions with a result.)
               lit: lib.seqLit(false), staged: {...lib.pipeStaged(false), alu: (s) => lib.valid(s, 0) && s("rd_valid", 0)?.asBool()}}),
            // Register file write.
            20: (lib) => lib.rfCfg(63, 0),
            // Branches (part 1): $taken_br and the branch's condition.
            21: (lib) => ({page: 66,
               primitives: {pc: [105, 106, 17, 41], datapath: [48, 49, 76, 77, 52, 53, 45, 31], inc_loop: [73, 75, 57, 50, 51, 35], reset: [39, 37],
                            src1: [29], alu: [46, 47, 33], rf_wr: [58, 59], rf_loop: [86, 87], br_cmp: [97, 98, 89, 91]},
               chips: {"taken_br@1": [425, 143]},
               stages: [[null, 140, 249], [12, 276, 249]], bounds: [177], cuts: {35: [106, "pc"], 31: [230, "src2"]},
               typeAt: lib.seqAt,
               lit: lib.seqLit(false), staged: lib.pipeStaged(false),
               marks: {row: (s) => { const i = ["beq", "bne", "blt", "bge", "bltu", "bgeu"].findIndex((op) => s("is_" + op, 1)?.asBool())
                  return i < 0 ? null : [433, 255 + 21 * i, 245, 19] }}}),
            // Branches (part 2): the branch-target path, lit when taken.
            22: (lib) => ({page: 67,
               primitives: {pc: [105, 106, 17, 37], datapath: [44, 45, 72, 73, 48, 49, 41, 27], inc_loop: [69, 71, 53, 46, 47, 31], reset: [35, 33],
                            src1: [25], alu: [42, 43, 29], rf_wr: [54, 55], rf_loop: [88, 89], br_cmp: [99, 100, 91, 93],
                            br_add: [64, 65, 59, 19, 23, 77, 79, 21], tgt_loop: [61, 67, 57, 51, 63, 96, 98, 102, 104]},
               chips: {"br_tgt_pc@1": [370, 90], "taken_br@1": [425, 143], "pc@0": [112, 172]},
               stages: [[null, 140, 249], [35, 276, 249]], bounds: [177], cuts: {31: [106, "pc"], 27: [230, "src2"]},
               typeAt: lib.seqAt,
               lit: lib.seqLit(true), staged: lib.pipeStaged(false)}),
            // Testbench: the checked value, |cpu/xreg[10]>>5$value (stage 1 + 5), which is 45 (passing) at the end.
            25: {page: 68,
               chips: {"/xreg[10]$value@6": [228, 180, "", (v) => v.asInt() + (v.asInt() === 45 ? " (passed)" : "")]}},
            // 3-cycle $valid: the mux (lit when valid), its 0 (reset) input, and the >>3$valid loop (lit when it provides 1).
            33: (lib) => ({page: 78,
               primitives: {mux: [115, 116], reset_in: [111, 113], loop: [108],
                            pc: [104, 105, 19, 37], datapath: [40, 41, 74, 75, 44, 45, 27], inc_loop: [71, 73, 49, 42, 43, 31], reset: [35, 33],
                            src1: [25], alu: [38, 39, 29], rf_wr: [50, 51], rf_loop: [80, 81], br_cmp: [98, 99, 87, 91, 89, 93],
                            br_add: [66, 67, 55, 57, 53, 61, 21, 23], tgt_loop: [63, 69, 59, 47, 65, 95, 97, 101, 103]},
               chips: {"reset@0": [95, 188, "reset="], "start@0": [95, 208, "start="], "valid@1": [238, 208]},
               // (The >>3$valid loop's forward part, from the mux, is staged.)
               stages: [[12, 159, 259], [14, 319, 259], [13, 520, 259], [39, 625, 259]], bounds: [196, 482, 562],
               cuts: {31: [103, "pc"], 27: [280, "src2"], 108: [158, 199.5, "datapath"]},
               typeAt: lib.seqAt,
               lit: {...lib.seqLit(true), mux: (s) => s("valid", 0).asBool(), reset_in: (s) => s("reset", 0).asBool(),
                     loop: (s) => s("valid", 0).asBool() && !s("start", 0).asBool()},
               staged: lib.pipeStaged(false)}),
            // 3-cycle RISC-V: the PC mux's >>3 inputs (branch-target loop, with its select, or the inc_pc loop),
            // and the $valid-gated RF write.
            36: (lib) => ({page: 79,
               primitives: {tgt_loop: [90, 94, 92, 56, 62, 106, 108, 102, 104], inc_loop: [64, 119, 29, 66, 58], wr_valid: [131, 54],
                            valid_mux: [126, 127], valid_loop: [25], reset_in: [88, 125],
                            inc: [49, 50, 37], datapath: [115, 116, 47, 48, 67, 68, 51, 52, 21, 43, 33], reset: [41, 39],
                            src1: [31], alu: [45, 46, 35], rf_wr: [132, 133], rf_loop: [72, 73], br_cmp: [111, 112, 96, 100, 98, 110],
                            br_add: [113, 114, 83, 85, 81, 60, 23, 27]},
               chips: {"valid_taken_br@3": [420, 62, "="], "br_tgt_pc@1": [470, 103], "inc_pc@3": [270, 74, "="],
                       "pc@0": [122, 100, "pc="], "valid@1": [240, 208, "="]},
               // (The >>3 loops' forward parts are staged: the target and inc_pc lines, split from @3, and the $valid rect's.)
               stages: [[37, 159, 259], [15, 340, 259], [29, 520, 259], [11, 625, 259]], bounds: [196, 490, 568, 640],
               split: {92: 3, 29: 3}, cuts: {37: [103, "datapath"], 33: [280, "src2"], 25: [158, 199.5, "datapath"]},
               typeAt: {tgt_loop: 3, inc_loop: 3, rf_loop: 2, wr_valid: 1},
               lit: {...lib.seqLit(), tgt_loop: (s) => !s("reset", 1).asBool() && s("valid_taken_br", 3)?.asBool(),
                     inc_loop: (s) => !s("reset", 1).asBool() && s("valid_taken_br", 3)?.asBool() === false && s("valid", 3)?.asBool(),
                     wr_valid: (s) => s("valid", 1).asBool(), valid_mux: (s) => s("valid", 0).asBool(),
                     valid_loop: (s) => s("valid", 0).asBool() && !s("start", 0).asBool(), reset_in: (s) => s("reset", 0).asBool()},
               staged: lib.pipeStaged(false)}),
            // Pipelined RISC-V (see pipeLit).
            37: (lib) => ({page: 80,
               primitives: {tgt_loop: [76, 80, 78, 51, 57, 100, 92, 88, 90], inc_loop: [59, 61, 53, 111, 27], rf_loop: [67, 68],
                            valid_loop: [23], valid_mux: [116, 115],
                            alu: [43, 42, 33],
                            rf_wr: [133, 134],
                            src1: [29], inc: [46, 47, 35], datapath: [19, 41, 31, 108, 45, 63, 49, 107, 44, 62, 48],
                            br_add: [106, 105, 96, 98, 94, 55, 21, 25], br_cmp: [104, 103, 82, 86, 102, 84, 132, 130]},
               chips: {"valid_taken_br@3": [412, 62, "="], "br_tgt_pc@3": [400, 104], "inc_pc@3": [262, 74, "="],
                       "pc@0": [125, 100, "pc="], "valid@1": [236, 208, "="],
                       "pc@1": [210, 124], "src1_value@3": [395, 152, "", undefined, "rf_rd_en1"],
                       "src2_value@3": [395, 190, "", undefined, "rf_rd_en2"], "result@3": [440, 164]},
               stages: [[39, 158, 234], [13, 250, 234], [37, 346, 234], [38, 436, 234], [36, 536, 234]],
               bounds: [196, 313, 391, 496], split: {78: 3, 27: 3},
               // The $valid loop (a rect): its forward part, from the mux into @3, is staged.
               cuts: {35: [103, "datapath"], 29: [380, "rd1_out"], 31: [[280, "src2"], [380, "rd2_out"]], 23: [[158, 199.5, "datapath"], [496, 199.5, "valid_loop"]]},
               typeAt: {inc_loop: 3},
               lit: lib.pipeLit, staged: lib.pipeStaged(false)}),
            // RF bypass: as above, plus each bypass mux (with the shared >>1 $rf_wr_data path) when it selects the previous write.
            39: (lib) => ({page: 83,
               primitives: {tgt_loop: [113, 117, 115, 53, 59, 131, 129, 127, 125], inc_loop: [147, 61, 55, 149, 143], rf_loop: [70],
                            valid_loop: [17], valid_mux: [25, 24], bypass: [91, 93], bypass1: [99, 95], bypass2: [97], src1: [101, 83, 100, 37], src2: [103, 81, 102],
                            alu: [111, 110, 41],
                            rf_wr: [140, 141],
                            inc: [150, 151, 145], datapath: [31, 39, 47, 49, 51, 63, 67, 48, 50, 62, 66],
                            br_add: [137, 136, 107, 109, 105, 57, 33, 35], br_cmp: [135, 134, 119, 123, 133, 121, 27, 19]},
               chips: {"valid_taken_br@3": [420, 62, "="], "br_tgt_pc@3": [380, 104], "inc_pc@3": [262, 74, "="],
                       "pc@0": [125, 100, "pc="], "valid@1": [236, 208, "="], ...lib.pipeChips},
               stages: [[null, 158, 234], [9, 256, 234], [12, 346, 234], [13, 436, 234], [8, 542, 234]],
               bounds: [196, 313, 421, 520], split: {115: 3, 143: 3},
               at: {140: 3, 141: 3}, cuts: {145: [103, "datapath"], 37: [380, "rd1_out"], 39: [[280, "src2"], [380, "rd2_out"]], 95: [195, "bypass"], 17: [158, 199.5, "datapath"]},
               typeAt: {inc_loop: 3},
               lit: {...lib.pipeLit, bypass1: (s) => lib.bypass(s, 1), bypass2: (s) => lib.bypass(s, 2),
                     bypass: (s) => lib.bypass(s, 1) || lib.bypass(s, 2)},
               staged: lib.pipeStaged()}),
            // Branches: the @3 instruction is invalid if either of the previous two was a taken branch.
            42: (lib) => {
               // (This design's $valid is @3, with no $start.)
               const {valid_loop, valid_mux, ...lit} = lib.cpuSlides[39](lib).lit
               return {page: 86,
                  primitives: {tgt_loop: [113, 117, 115, 47, 55, 129, 137, 125, 127], inc_loop: [57, 59, 49], rf_loop: [65, 66],
                               bypass: [97, 99], bypass1: [105, 101], bypass2: [103], src1: [107, 89, 106, 27], src2: [109, 87, 108],
                               br: [141], br1: [164, 162, 160], br2: [145, 158, 150], kill: [170, 168, 166, 15, 167, 169],
                               alu: [111, 110, 31],
                               rf_wr: [50, 51],
                               inc: [42, 43, 33], datapath: [21, 29, 39, 41, 45, 61, 153, 40, 44, 60, 152],
                               br_add: [143, 142, 133, 135, 131, 53, 23, 25], br_cmp: [147, 146, 119, 123, 139, 121]},
                  chips: {"valid_taken_br@3": [400, 118, "="], "br_tgt_pc@3": [372, 102], "inc_pc@1": [245, 88, "="],
                          "pc@0": [125, 100, "pc="], "valid@3": [501, 139, "="], ...lib.pipeChips},
                  stages: [[null, 158, 234], [9, 256, 234], [12, 346, 234], [13, 436, 234], [8, 542, 234], [null, 645, 234]],
                  bounds: [196, 313, 421, 520, 616], split: {115: 3, 141: 3}, at: {50: 3, 51: 3}, cuts: {33: [103, "datapath"], 27: [380, "rd1_out"], 29: [[280, "src2"], [380, "rd2_out"]], 101: [195, "bypass"]},
                  lit: {...lit, inc_loop: (s) => !s("reset", 1).asBool() && s("valid_taken_br", 3)?.asBool() === false && lib.incUsed(s, 1),
                        br: (s) => s("valid_taken_br", 3)?.asBool(), br1: (s) => s("valid_taken_br", 4)?.asBool(),
                        br2: (s) => s("valid_taken_br", 5)?.asBool(), kill: (s) => s("valid", 3)?.asBool() === false},
                  staged: lib.pipeStaged()}
            },
            // Complete decode: the decoded instruction's table row (loads: all L* rows).
            44: {page: 87,
               chips: {"dec_bits@1": [640, 164, "", (v) => { const b = v.asBinaryStr("?"); return b[0] + "_" + b.slice(1, 4) + "_" + b.slice(4) }]},
               marks: {row: (s) => {
                  const left = "lui auipc jal jalr beq bne blt bge bltu bgeu load - - - - sb sh sw addi slti".split(" "),
                        right = "sltiu xori ori andi slli srli srai add sub sll slt sltu xor srl sra or and".split(" "),
                        op = [...left, ...right].find((op) => op !== "-" && s("is_" + op, 1)?.asBool())
                  if (!op) return null
                  const i = left.indexOf(op)
                  return i >= 0 ? [60, 109 + 13.33 * i, 178, op === "load" ? 66.7 : 13.3]
                                : [252, 140 + 13.33 * right.indexOf(op), 190, 13.3] }}},
            // Complete ALU: the @3 instruction's $result expression.
            45: {page: 88,
               chips: {"result@3": [200, 76, "$result="]},
               marks: {row: (s) => {
                  // [left, label top, width] by mnemonic.
                  const rows = {andi: [72, 113.1, 242], ori: [72, 132.6, 242], xori: [72, 152.1, 242], addi: [72, 171.6, 242],
                                slli: [72, 191.1, 242], srli: [72, 210.6, 242], and: [72, 230.1, 242], or: [72, 249.6, 242],
                                xor: [72, 269.1, 242], srai: [72, 299.6, 620], slt: [72, 319.1, 620], slti: [72, 338.6, 620],
                                sra: [72, 358.1, 620], add: [390, 95.9, 275], sub: [390, 115.4, 275], sll: [390, 134.9, 275],
                                srl: [390, 154.4, 275], sltu: [390, 173.9, 275], sltiu: [390, 193.4, 275], lui: [390, 212.9, 160],
                                auipc: [390, 232.4, 160], jal: [390, 251.9, 160], jalr: [390, 271.4, 160]}
                  const op = Object.keys(rows).find((op) => s("is_" + op, 3)?.asBool())
                  return op && [rows[op][0], rows[op][1] - 1.5, rows[op][2], 19] }}},
            // Redirect Loads: as slide 39 (no $valid logic), plus the >>3$inc_pc loop (red) for a load in @3.
            48: (lib) => {
               const {valid_loop, valid_mux, ...lit} = lib.cpuSlides[39](lib).lit
               const ld = (s) => !s("reset", 1).asBool() && !s("valid_taken_br", 3)?.asBool() && s("valid_load", 3)?.asBool()
               return {page: 92,
                  primitives: {tgt_loop: [95, 97, 99, 45, 53, 113, 115, 117, 119], inc_loop: [55, 57, 47], ld_loop: [139, 141, 143, 145, 147],
                               rf_loop: [63, 64], bypass: [79, 81, 83], bypass1: [87], bypass2: [85], src1: [89, 76, 88, 25], src2: [91, 74, 90],
                               ldst: [127, 133, 134, 135],
                               alu: [93, 92, 29],
                               rf_wr: [48, 49],
                               inc: [40, 41, 31], datapath: [19, 27, 37, 39, 43, 59, 149, 38, 42, 58, 148],
                               br_add: [123, 122, 109, 111, 107, 51, 21, 23], br_cmp: [125, 124, 101, 105, 103, 121]},
                  chips: {"pc@0": [118, 100, "pc="], "valid_taken_br@3": [505, 127, "="], "inc_pc@3": [330, 52, "inc_pc="],
                          "valid_load@3": [535, 68, "valid_load="], "valid@3": [690, 130, "valid="], ...lib.pipeChips},
                  stages: [[null, 158, 265], [9, 256, 265], [11, 364, 265], [12, 466, 265], [8, 560, 265], [19, 638, 265]],
                  bounds: [196, 313, 421, 520, 598], split: {97: 3, 139: 3, 133: 3}, at: {48: 3, 49: 3}, cuts: {31: [103, "datapath"], 25: [380, "rd1_out"], 27: [[280, "src2"], [380, "rd2_out"]], 83: [148, "bypass2"]},
                  lit: {...lit, ld_loop: ld, inc_loop: (s) => !s("reset", 1).asBool() && s("valid_taken_br", 3)?.asBool() === false && !ld(s) && lib.incUsed(s, 1),
                        ldst: (s) => s("valid", 3)?.asBool() && (s("is_load", 3).asBool() || s("is_s_instr", 3).asBool())},
                  staged: lib.pipeStaged()}
            },
            // Load Data: as slide 48, plus the ld/st address to DMem and the RF write-data mux (red) selecting
            // $result or >>2$ld_data.
            49: (lib) => {
               const {page, primitives, ...cfg} = lib.cpuSlides[48](lib), ld = (s) => s("valid_load", 5)?.asBool()
               return {...cfg, page: 93,
                  primitives: {tgt_loop: [96, 98, 100, 45, 53, 108, 110, 118, 120], inc_loop: [55, 57, 47], ld_loop: [150, 152, 154, 156, 158],
                               rf_loop: [63, 64], bypass: [80, 82, 84], bypass1: [88], bypass2: [86], src1: [90, 76, 89, 25], src2: [92, 74, 91],
                               ldst: [128, 134], alu_wr: [29], ld_wr: [163, 139, 141, 143, 145], wr_mux: [147, 146],
                               alu: [94, 93],
                               rf_wr: [48, 49],
                               inc: [40, 41, 31], datapath: [19, 27, 37, 39, 43, 59, 160, 38, 42, 58, 159],
                               br_add: [124, 123, 114, 116, 112, 51, 21, 23], br_cmp: [126, 125, 102, 106, 122, 104]},
                  stages: cfg.stages.map(([t, ...pos], k) => [k === 5 ? 46 : t, ...pos]), split: {98: 3, 150: 3, 134: 3},
                  cuts: {31: [103, "datapath"], 25: [380, "rd1_out"], 27: [[280, "src2"], [380, "rd2_out"]], 84: [148, "bypass2"]},
                  chips: {...cfg.chips, "rf_wr_index@3": [668, 148, "rf_wr_index="], "rf_wr_data@3": [668, 164, "rf_wr_data="]},
                  lit: {...cfg.lit, alu_wr: (s) => s("rf_wr_en", 3).asBool() && !ld(s), ld_wr: ld, wr_mux: (s) => s("rf_wr_en", 3).asBool()}}
            },
            // DMem: slide 49's datapath (cropped), plus the st data path and DMem (red) and the DMem interface values.
            51: (lib) => {
               const {lit} = lib.cpuSlides[49](lib)
               return {page: 94,
                  primitives: {tgt_loop: [65, 67, 69, 77, 79], ld_loop: [116, 118, 120], rf_loop: [36, 37],
                               bypass: [49, 51, 53], bypass1: [57], bypass2: [55], src1: [59, 45, 58, 20], src2: [61, 43, 60, 22],
                               ldst: [95, 101], alu_wr: [24], ld_wr: [105, 107, 109, 111], wr_mux: [113, 112], st_data: [90, 92], dmem: [103, 102],
                               alu: [63, 62],
                               rf_wr: [29, 30],
                               datapath: [26, 28, 27],
                               br_add: [85, 84, 81, 32, 16, 18], br_cmp: [87, 86, 71, 75, 83, 73]},
                  // (The DMem inputs, left-aligned at their pins.)
                  chips: {...Object.fromEntries(["reset", "dmem_wr_en", "dmem_addr", "dmem_wr_data", "dmem_rd_en"].map((n, k) =>
                             [n + "@4", [539, [135, 148, 162, 176, 189][k], "", undefined, undefined, "left"]])),
                          "dmem_rd_data@4": [647, 178], "ld_data@5": [300, 224, "="],
                          "src1_value@3": [116, 141, "", undefined, "rf_rd_en1"], "src2_value@3": [116, 191, "", undefined, "rf_rd_en2"], "result@3": [163, 158]},
                  // (The ld/st address line continues as the load data, lit as ld/st.)
                  stages: [, , [6, 48, 259], [7, 150, 259], [5, 244, 259], [23, 322, 259]],
                  bounds: [-Infinity, -Infinity, 105, 204, 282], split: {67: 3, 116: 3, 101: 3, 92: 4},
                  at: {29: 3, 30: 3}, cuts: {20: [64, "rd1_out"], 22: [64, "rd2_out"], 53: [142, "bypass2"]},
                  lit: {...lit, st_data: (s) => s("dmem_wr_en", 4)?.asBool(),
                        dmem: (s) => s("dmem_wr_en", 4)?.asBool() || s("valid_load", 4)?.asBool()},
                  staged: lib.pipeStaged()}
            },
            // Load/store in program: marks the SW/LW line in @4 (DMem), with the stored word (m4_asm immediates are binary,
            // so byte address 4, dmem[1]) and the checked value, |cpu/xreg[15]>>5$value.
            52: {page: 95,
               chips: {"/dmem[1]$value@5": [345, 156, "dmem[1]=", (v) => v.asInt()],
                       "/xreg[15]$value@6": [490, 226, "= ", (v) => v.asInt() + (v.asInt() === 45 ? " (passed)" : "")]},
               marks: {sw: (s) => s("dmem_wr_en", 4)?.asBool() ? [95, 147, 212, 17] : null,
                       lw: (s) => s("valid_load", 4)?.asBool() ? [95, 171, 212, 17] : null}},
            // Jumps: as slide 49 (no >>3$inc_pc loop drawn), with the target loop (red) also taken by jumps, and the JALR
            // target adder (red). (The test program has no jumps.)
            53: (lib) => {
               const {page, primitives, chips: {"valid_load@3": vl, ...chips}, lit: {ld_loop, ...lit}, ...cfg} = lib.cpuSlides[49](lib)
               const jump = (s) => s("valid_jump", 3)?.asBool()
               return {...cfg, page: 97,
                  primitives: {tgt_loop: [94, 96, 98, 45, 53, 106, 108, 110, 112, 155], jalr: [151, 153, 152], inc_loop: [55, 57, 47],
                               rf_loop: [63, 64], bypass: [80, 82, 149], bypass1: [86], bypass2: [84], src1: [88, 76, 87, 25], src2: [90, 74, 89],
                               ldst: [124, 130], alu_wr: [29], ld_wr: [135, 137, 139, 141], wr_mux: [143, 142],
                               alu: [92, 91],
                               rf_wr: [48, 49],
                               inc: [40, 41, 31], mem: [131, 132], datapath: [19, 27, 37, 39, 43, 59, 146, 38, 42, 58, 145],
                               br_add: [122, 121, 116, 118, 114, 51, 21, 23], br_cmp: [100, 104, 120, 102]},
                  stages: cfg.stages.map(([t, ...pos], k) => [k === 5 ? 38 : t, ...pos]), split: {96: 3, 151: 3, 130: 3},
                  cuts: {31: [103, "datapath"], 25: [380, "rd1_out"], 27: [[280, "src2"], [380, "rd2_out"]], 82: [148, "bypass2"]},
                  chips: {...chips, "valid_jump@3": [535, 68, "valid_jump="], "jalr_tgt_pc@3": [645, 68, "jalr_tgt_pc="]},
                  lit: {...lit, tgt_loop: (s) => lit.tgt_loop(s) || !s("reset", 1).asBool() && jump(s),
                        inc_loop: (s) => lit.inc_loop(s) && !jump(s),
                        jalr: (s) => jump(s) && s("is_jalr", 3).asBool()}}
            },
         },
      },


// ===================
// Calculator Slides
// ===================

// The slide for the calculator lab being built (by m4_lab_* flags).
\TLV myth_calc_slide(/_top)
   m4_ifelse_block(m4_lab_12, 1, [''], m4_lab_11, 1, ['
   m4+calc_slide43(/_top)
   '], m4_lab_10, 1, ['
   m4+calc_slide41(/_top)
   '], m4_lab_9, 1, ['
   m4+calc_slide36(/_top)
   '], m4_lab_8, 1, ['
   m4+calc_slide35(/_top)
   '], m4_lab_6, 1, ['
   m4+calc_slide23(/_top)
   '])

// Slide 23: Sequential Calculator.
\TLV calc_slide23(/_top)
   |calc
      /slide
         @M4_OUTPUT_STAGE
            \viz_js
               box: {width: 720, height: 405, strokeWidth: 0},
               where: {left: -620, top: 110},
               init() {
                  const lib = '/_top/myth_lib'.lib
                  return lib.init(this, {page: 25, pipe: "calc",
                     bounds: [-Infinity], staged: lib.calcStaged(), lit: lib.calcLoop,
                     primitives: {op0: [35, 37, 50, 51, 18], op1: [41, 43, 52, 53, 20], op2: [45, 47, 54, 55, 22], op3: [49, 16, 56, 57, 24],
                                  val: [33, 31, 39, 76, 78], loop: [88, 90, 92], always: [115, 116, 59, 93, 94, 96, 98, 100, 102],
                                  reset_path: [109, 111], zero_path: [114, 9]},
                     chips: {"op@1": [470, 174, "", (v) => (v.asInt() & 3).toString(16)], "val1@1": [372, 262], "val2@1": [390, 294], "out@1": [614, 262]}})
               },
               render() {
                  '/_top/myth_lib'.lib.cpuRender(this)
               },

// Slide 35: Counter and Calculator in Pipeline.
\TLV calc_slide35(/_top)
   |calc
      /slide
         @M4_OUTPUT_STAGE
            \viz_js
               box: {width: 720, height: 405, strokeWidth: 0},
               where: {left: -620, top: 110},
               init() {
                  const lib = '/_top/myth_lib'.lib
                  return lib.init(this, {page: 37, pipe: "calc",
                     bounds: [-Infinity], staged: lib.calcStaged(), lit: lib.calcLoop,
                     primitives: {op0: [75, 77, 90, 91, 62], op1: [81, 83, 92, 93, 64], op2: [85, 87, 94, 95, 66], op3: [89, 60, 96, 97, 68],
                                  val: [73, 71, 79, 102, 104], loop: [112, 114, 116], always: [105, 106, 43, 44, 23, 25, 31, 33, 35],
                                  run: [47, 48, 37, 46], reset_path: [21, 58, 42, 39], zero_path: [52, 56]},
                     chips: {"op@1": [480, 118, "", (v) => (v.asInt() & 3).toString(16)], "val1@1": [400, 183], "val2@1": [400, 246], "out@1": [645, 246], "cnt@1": [575, 309]}})
               },
               render() {
                  '/_top/myth_lib'.lib.cpuRender(this)
               },

// Slide 36: 2-Cycle Calculator. (@1 | @2 | @3 at x = 525, 636. The $out loop (a polyline) is cut so its part inside the
// pipeline is staged, as $out (lit like the mux), split into @2 and @3.)
\TLV calc_slide36(/_top)
   |calc
      /slide
         @M4_OUTPUT_STAGE
            \viz_js
               box: {width: 720, height: 405, strokeWidth: 0},
               where: {left: -620, top: 110},
               init() {
                  const lib = '/_top/myth_lib'.lib
                  return lib.init(this, {page: 38, pipe: "calc",
                     bounds: [-Infinity, 525, 636], staged: lib.calcStaged(), lit: lib.calcLoop,
                     cuts: {123: [[606.7, 206.9, "always"], [669.8, 110, "always"]]},
                     primitives: {op0: [86, 88, 101, 102, 73], op1: [92, 94, 103, 104, 75], op2: [96, 98, 105, 106, 77], op3: [100, 71, 107, 108, 79],
                                  val: [84, 82, 90, 113, 115], loop: [123, 125, 127, 133],
                                  always: [116, 117, 46, 47, 26, 28, 34, 36, 38, 135], run: [50, 51, 40, 49],
                                  reset_path: [24, 65, 45, 42], zero_path: [55, 63, 67, 68, 69], invalid_path: [58, 60, 136, 137, 138, 139]},
                     chips: {"op@1": [480, 118, "", (v) => (v.asInt() & 3).toString(16)], "val1@1": [400, 183], "val2@1": [400, 246], "out@2": [645, 246], "valid@2": [612, 330]}})
               },
               render() {
                  '/_top/myth_lib'.lib.cpuRender(this)
               },

// Slide 41: 2-Cycle Calculator with Validity. (The crossed-out logic is hidden.)
\TLV calc_slide41(/_top)
   |calc
      /slide
         @M4_OUTPUT_STAGE
            \viz_js
               box: {width: 720, height: 405, strokeWidth: 0},
               where: {left: -620, top: 110},
               init() {
                  const lib = '/_top/myth_lib'.lib
                  return lib.init(this, {page: 42, pipe: "calc",
                     bounds: [-Infinity, 525, 636], staged: lib.calcStaged(), lit: lib.calcLoop,
                     cuts: {125: [[606.7, 206.9, "active"], [669.8, 110, "active"]]},
                     primitives: {op0: [88, 90, 103, 104, 75], op1: [94, 96, 105, 106, 77], op2: [98, 100, 107, 108, 79], op3: [102, 73, 109, 110, 81],
                                  val: [86, 84, 92, 115, 117], loop: [125, 127, 129, 167], always: [48, 49, 28, 30, 36, 38, 40],
                                  run: [52, 53, 42, 51], reset_path: [26, 67, 165, 69, 47, 159, 57, 65, 44], active: [157, 161, 163, 118, 119],
                                  hidden: [60, 62, 70, 71, 134, 135, 136, 137, 139, 141]},
                     chips: {"op@1": [480, 118, "", (v) => (v.asInt() & 3).toString(16)], "val1@1": [400, 183], "val2@1": [400, 246], "out@2": [645, 246], "valid@2": [549, 330]}})
               },
               render() {
                  '/_top/myth_lib'.lib.cpuRender(this)
               },

// Slide 43: Calculator with Single-Value Memory. ($op 4 is recall; 5 is mem. $mem's register (the mem mux and
// its >>2 loop, outside the pipeline) is active when $reset || $valid in @2.)
\TLV calc_slide43(/_top)
   |calc
      /slide
         @M4_OUTPUT_STAGE
            \viz_js
               box: {width: 720, height: 405, strokeWidth: 0},
               where: {left: -620, top: 110},
               init() {
                  const lib = '/_top/myth_lib'.lib
                  return lib.init(this, {page: 43, pipe: "calc",
                     bounds: [-Infinity, 525, 648], staged: lib.calcStaged(3), cuts: {118: [[606.7, 194.9, "active"], [669.8, 100, "active"]]},
                     lit: {...lib.calcLoop, mem_loop: (s) => s("reset", 2)?.asBool() || s("valid", 2)?.asBool() !== false},
                     primitives: {op0: [83, 85, 98, 99, 70], op1: [89, 91, 100, 101, 72], op2: [93, 95, 102, 103, 74], op3: [97, 68, 104, 105, 76],
                                  op4: [144], op5: [152], val: [81, 79, 87, 110, 112, 169, 155], loop: [118, 120, 122, 157],
                                  mem_loop: [138, 159, 140, 163], always: [51, 52, 31, 33, 39, 41, 43], run: [55, 56, 45, 54],
                                  reset_path: [29, 66, 50, 132, 60, 64, 161, 148, 47, 20], hold: [165],
                                  active: [130, 134, 136, 145, 146, 166, 167, 142]},
                     chips: {"op@1": [415, 106], "val1@1": [425, 214], "val2@1": [400, 246], "out@2": [640, 246], "mem@2": [664, 152], "valid@2": [549, 330]}})
               },
               render() {
                  '/_top/myth_lib'.lib.cpuRender(this)
               },


// ===================
// RISC-V Slides
// ===================

// The slide for the RISC-V lab being built (the last lab at or before m4_slide; see cpuSlides in the library).
\TLV myth_cpu_slide(/_top)
   |cpu
      /slide
         @0
            \viz_js
               box: {width: 720, height: 405, strokeWidth: 0},
               where: {left: -1660, top: -20, scale: 1.4},
               init() {
                  return '/_top/myth_lib'.lib.cpuInit(this, m4_slide)
               },
               render() {
                  '/_top/myth_lib'.lib.cpuRender(this)
               },
