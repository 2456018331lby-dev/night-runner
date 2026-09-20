/* Build a CJK font subset for Night Runner.
 * Scans the project source for every character actually used, adds a safety
 * set (ASCII + CJK punctuation + digits), subsets Noto Sans SC to those glyphs
 * and writes assets/fonts/noto_sans_sc_subset.ttf.
 * Re-run whenever new in-game copy adds characters.
 *   NODE_PATH=<global node_modules> node tools/build_font_subset.js <sourceFont.ttf> <outPath>
 */
const fs = require('fs');
const path = require('path');
const subsetFont = require('subset-font');

const ROOT = 'C:/Users/24560/Desktop/study/gametwo';
const SRC_FONT = process.argv[2];
const OUT_FONT = process.argv[3];
const SCAN_DIRS = ['scripts', 'scenes', 'data', 'autoload'].map((d) => path.join(ROOT, d));

function walk(dir, acc) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, acc);
    else if (/\.(gd|tscn|tres|godot|cfg)$/.test(e.name)) acc.push(p);
  }
  return acc;
}

(async () => {
  const files = SCAN_DIRS.filter((d) => fs.existsSync(d)).flatMap((d) => walk(d, []));
  const used = new Set();
  for (const f of files) {
    const text = fs.readFileSync(f, 'utf8');
    for (const ch of text) {
      const c = ch.codePointAt(0);
      // CJK unified + Ext-A basics, CJK punctuation, fullwidth forms
      if (c >= 0x2e80) used.add(ch);
    }
  }
  const charset = new Set(used);
  for (let c = 0x20; c <= 0x7e; c++) charset.add(String.fromCodePoint(c)); // ASCII
  for (const ch of '　、。·ˉˇ¨〃々—～‖…‘’“”〔〕〈〉《》「」『』〖〗【】！＃￥％＆＊：；？，（）－．／') charset.add(ch);
  for (let c = 0xff01; c <= 0xff5e; c++) charset.add(String.fromCodePoint(c)); // fullwidth forms
  for (let c = 0x2000; c <= 0x206f; c++) charset.add(String.fromCodePoint(c)); // general punctuation
  for (let c = 0x2150; c <= 0x218b; c++) charset.add(String.fromCodePoint(c)); // numerals
  for (let c = 0x2460; c <= 0x24ff; c++) charset.add(String.fromCodePoint(c)); // enclosed alphanumerics
  const chars = [...charset].join('');
  console.log('scan files:', files.length, 'unique CJK-ish:', used.size, 'charset total:', chars.length);

  const src = fs.readFileSync(SRC_FONT);
  const subset = await subsetFont(src, chars, { targetFormat: 'truetype' });
  fs.mkdirSync(path.dirname(OUT_FONT), { recursive: true });
  fs.writeFileSync(OUT_FONT, subset);
  console.log('src bytes:', src.length, 'subset bytes:', subset.length, '->', OUT_FONT);
})().catch((e) => { console.error('FATAL', e && e.message); process.exit(1); });
