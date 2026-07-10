import '../../config/power_config.dart';

/// Genera el documento HTML/CSS autocontenido del avatar cabezón para
/// renderizarlo en un WebView ([warrior_avatar_view.dart]).
///
/// Todo es CSS puro (sin imágenes ni recursos externos) para respetar el CSP
/// del WebView y poder pintar con fondo transparente sobre la UI de Flutter.
///
/// - [gender]: variante (se traduce a la clase `g-male|g-female|g-neutral`).
/// - [power]: Nivel de Poder → determina el tier (aura, cinturón, marco, FX).
/// - [schoolColorHex]: color primario de la escuela (`#RRGGBB`), usado como
///   acento en la vincha y el cuello del kimono.
/// - [skinHex]: tono de piel (`#RRGGBB`).
String buildAvatarHtml({
  required AvatarGender gender,
  required int power,
  required String schoolColorHex,
  String skinHex = '#ffd9b0',
}) {
  final tier = tierForPower(power);
  return '''<!doctype html>
<html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>
  :root{
    --t1:#c98a4b;   /* bronce  */
    --t2:#9fb7d4;   /* acero   */
    --t3:#f5c451;   /* oro     */
    --epic-a:#b061ff; --epic-b:#ff5db1;
  }
  html,body{margin:0;height:100%;background:transparent;overflow:hidden}
  body{display:flex;align-items:center;justify-content:center}
  .scale{transform:scale(1.35);transform-origin:center}

  .warrior{
    --skin:$skinHex; --skin-2:#f0b98a;
    --hair:#3a2c25; --hair-2:#2a1f1a;
    --gi:#f4f1ea; --gi-2:#d9d3c6;
    --accent:$schoolColorHex;
    --belt:#e9e6df; --aura:transparent; --metal:transparent;
    position:relative;width:150px;height:170px;
  }
  .aura{position:absolute;left:50%;top:44%;transform:translate(-50%,-50%);
    width:150px;height:150px;border-radius:50%;
    background:radial-gradient(circle,var(--aura) 0%,transparent 62%);opacity:.9;filter:blur(4px)}
  .ring{position:absolute;left:50%;top:44%;transform:translate(-50%,-50%);
    width:158px;height:158px;border-radius:50%;border:2px solid var(--metal);opacity:0}
  .char{position:absolute;inset:0;z-index:2;animation:bob 4s ease-in-out infinite}

  .body{position:absolute;left:50%;bottom:0;transform:translateX(-50%);width:118px;height:74px}
  .gi{position:absolute;bottom:0;left:50%;transform:translateX(-50%);width:112px;height:66px;
    background:linear-gradient(180deg,var(--gi),var(--gi-2));border-radius:40px 40px 20px 20px;
    box-shadow:inset 0 -6px 10px rgba(0,0,0,.06)}
  .gi::before,.gi::after{content:"";position:absolute;top:2px;width:0;height:0;border-style:solid}
  .gi::before{left:50%;margin-left:-30px;border-width:0 30px 44px 0;
    border-color:transparent var(--gi-2) transparent transparent;opacity:.55}
  .gi::after{right:50%;margin-right:-30px;border-width:44px 30px 0 0;
    border-color:var(--gi-2) transparent transparent transparent;opacity:.35}
  .collar{position:absolute;top:0;left:50%;transform:translateX(-50%);width:44px;height:34px;
    background:var(--accent);clip-path:polygon(50% 0,68% 0,50% 40%,32% 0);opacity:.92}
  .belt{position:absolute;bottom:12px;left:50%;transform:translateX(-50%);width:118px;height:15px;
    border-radius:6px;background:linear-gradient(180deg,var(--belt),color-mix(in srgb,var(--belt) 70%,#000));
    box-shadow:0 2px 5px rgba(0,0,0,.25)}
  .belt::after{content:"";position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);
    width:20px;height:20px;border-radius:5px;
    background:linear-gradient(180deg,var(--belt),color-mix(in srgb,var(--belt) 60%,#000));
    box-shadow:0 1px 3px rgba(0,0,0,.3)}
  .arm{position:absolute;bottom:14px;width:22px;height:30px;border-radius:12px;
    background:linear-gradient(180deg,var(--gi),var(--gi-2))}
  .arm.l{left:-2px;transform:rotate(8deg)}.arm.r{right:-2px;transform:rotate(-8deg)}
  .fist{position:absolute;bottom:10px;width:17px;height:17px;border-radius:50%;
    background:radial-gradient(circle at 35% 30%,var(--skin),var(--skin-2))}
  .fist.l{left:-1px}.fist.r{right:-1px}

  .head{position:absolute;left:50%;top:6px;transform:translateX(-50%);width:118px;height:112px;z-index:3}
  .ear{position:absolute;top:52px;width:20px;height:24px;border-radius:50%;
    background:radial-gradient(circle at 40% 35%,var(--skin),var(--skin-2))}
  .ear.l{left:-4px}.ear.r{right:-4px}
  .skull{position:absolute;inset:0;
    background:radial-gradient(120% 120% at 35% 28%,var(--skin) 0%,var(--skin-2) 100%);
    border-radius:47% 47% 44% 44%/52% 52% 48% 48%;
    box-shadow:inset -6px -8px 14px rgba(0,0,0,.08),inset 6px 6px 12px rgba(255,255,255,.28)}
  .face{position:absolute;inset:0;z-index:4}
  .eye{position:absolute;top:58px;width:19px;height:23px;border-radius:50%;background:#2a2230}
  .eye.l{left:30px}.eye.r{right:30px}
  .eye .glint{position:absolute;top:4px;left:4px;width:7px;height:7px;border-radius:50%;background:#fff;opacity:.95}
  .eye .glint.s{top:12px;left:10px;width:3px;height:3px;opacity:.7}
  .brow{position:absolute;top:49px;width:18px;height:5px;border-radius:3px;background:var(--hair-2)}
  .brow.l{left:31px;transform:rotate(-6deg)}.brow.r{right:31px;transform:rotate(6deg)}
  .blush{position:absolute;top:74px;width:15px;height:9px;border-radius:50%;background:#ff9a9a;opacity:.55;filter:blur(.5px)}
  .blush.l{left:20px}.blush.r{right:20px}
  .mouth{position:absolute;top:82px;left:50%;transform:translateX(-50%);width:22px;height:11px;
    border-radius:0 0 14px 14px;background:#7a3b3b;box-shadow:inset 0 3px 0 rgba(255,255,255,.15)}

  .hair{position:absolute;inset:0;z-index:5;pointer-events:none}
  .g-male .hair::before{content:"";position:absolute;top:-4px;left:8px;right:8px;height:52px;
    background:linear-gradient(180deg,var(--hair),var(--hair-2));border-radius:50% 50% 40% 40%/70% 70% 30% 30%;
    clip-path:polygon(0 60%,8% 20%,20% 55%,32% 8%,46% 50%,50% 4%,54% 50%,68% 8%,80% 55%,92% 20%,100% 60%,100% 100%,0 100%)}
  .g-female .hair::before{content:"";position:absolute;top:-6px;left:2px;right:2px;height:62px;
    background:linear-gradient(180deg,var(--hair),var(--hair-2));border-radius:50% 50% 46% 46%/60% 60% 40% 40%;
    clip-path:polygon(0 78%,0 30%,18% 6%,50% 0,82% 6%,100% 30%,100% 78%,86% 52%,72% 74%,60% 50%,50% 72%,40% 50%,28% 74%,14% 52%)}
  .g-female .hair::after{content:"";position:absolute;top:-14px;left:50%;transform:translateX(-50%);
    width:34px;height:34px;border-radius:50%;background:radial-gradient(circle at 38% 32%,var(--hair),var(--hair-2))}
  .g-neutral .hair::before{content:"";position:absolute;top:-4px;left:6px;right:6px;height:50px;
    background:linear-gradient(180deg,var(--hair),var(--hair-2));border-radius:52% 52% 42% 42%/66% 66% 34% 34%}
  .g-neutral .hair::after{content:"";position:absolute;top:-2px;left:50%;width:10px;height:16px;
    background:var(--hair);border-radius:6px;transform:translateX(-50%) rotate(6deg)}

  .band{position:absolute;top:44px;left:-2px;right:-2px;height:15px;z-index:6}
  .band .strip{position:absolute;inset:0;border-radius:8px;
    background:linear-gradient(180deg,var(--accent),color-mix(in srgb,var(--accent) 65%,#000));
    box-shadow:0 1px 3px rgba(0,0,0,.3),inset 0 1px 0 rgba(255,255,255,.25)}
  .band .knot{position:absolute;right:-3px;top:-1px;width:14px;height:14px;border-radius:4px;
    background:linear-gradient(180deg,var(--accent),color-mix(in srgb,var(--accent) 60%,#000));transform:rotate(20deg)}
  .band .tail{position:absolute;right:-8px;width:8px;height:26px;border-radius:4px;
    background:linear-gradient(180deg,var(--accent),color-mix(in srgb,var(--accent) 60%,#000))}
  .band .tail.t1{top:6px;transform:rotate(28deg)}
  .band .tail.t2{top:8px;right:-2px;transform:rotate(48deg);opacity:.85}

  .spark{position:absolute;width:8px;height:8px;border-radius:50%;
    background:radial-gradient(circle,#fff,transparent 60%);opacity:0}
  .s1{top:12px;left:14px}.s2{top:30px;right:10px}.s3{top:70px;left:4px}.s4{top:96px;right:16px;width:6px;height:6px}

  .warrior[data-tier="1"]{--belt:var(--t1);--aura:color-mix(in srgb,var(--t1) 34%,transparent)}
  .warrior[data-tier="2"]{--belt:var(--t2);--aura:color-mix(in srgb,var(--t2) 40%,transparent);--metal:var(--t2)}
  .warrior[data-tier="2"] .ring{opacity:.55}
  .warrior[data-tier="2"] .spark{opacity:.8;animation:twk 2.6s ease-in-out infinite}
  .warrior[data-tier="3"]{--belt:var(--t3);--aura:color-mix(in srgb,var(--t3) 46%,transparent);--metal:var(--t3)}
  .warrior[data-tier="3"] .aura{animation:breathe 3.2s ease-in-out infinite}
  .warrior[data-tier="3"] .char{animation:bob 3s ease-in-out infinite}
  .warrior[data-tier="3"] .ring{opacity:.9;border-color:transparent;
    background:conic-gradient(from 0deg,var(--epic-a),var(--t3),var(--epic-b),var(--epic-a));
    -webkit-mask:radial-gradient(farthest-side,transparent calc(100% - 3px),#000 calc(100% - 3px));
            mask:radial-gradient(farthest-side,transparent calc(100% - 3px),#000 calc(100% - 3px));
    animation:spin 8s linear infinite}
  .warrior[data-tier="3"] .spark{opacity:1;animation:twk 2s ease-in-out infinite}
  .warrior[data-tier="3"] .band .strip{
    box-shadow:0 0 10px color-mix(in srgb,var(--t3) 70%,transparent),inset 0 1px 0 rgba(255,255,255,.35)}

  @keyframes bob{0%,100%{transform:translateY(0)}50%{transform:translateY(-4px)}}
  @keyframes breathe{0%,100%{opacity:.75;transform:translate(-50%,-50%) scale(1)}
    50%{opacity:1;transform:translate(-50%,-50%) scale(1.08)}}
  @keyframes spin{to{transform:translate(-50%,-50%) rotate(360deg)}}
  @keyframes twk{0%,100%{transform:scale(.6);opacity:.2}50%{transform:scale(1.15);opacity:1}}
  @media (prefers-reduced-motion:reduce){.char,.aura,.ring,.spark{animation:none!important}}
</style></head>
<body><div class="scale">
  <div class="warrior g-${gender.slug}" data-tier="${tier.index}">
    <div class="aura"></div><div class="ring"></div>
    <div class="spark s1"></div><div class="spark s2"></div>
    <div class="spark s3"></div><div class="spark s4"></div>
    <div class="char">
      <div class="body">
        <div class="arm l"></div><div class="fist l"></div>
        <div class="arm r"></div><div class="fist r"></div>
        <div class="gi"></div><div class="collar"></div><div class="belt"></div>
      </div>
      <div class="head">
        <div class="ear l"></div><div class="ear r"></div>
        <div class="skull"></div><div class="hair"></div>
        <div class="face">
          <div class="brow l"></div><div class="brow r"></div>
          <div class="eye l"><span class="glint"></span><span class="glint s"></span></div>
          <div class="eye r"><span class="glint"></span><span class="glint s"></span></div>
          <div class="blush l"></div><div class="blush r"></div>
          <div class="mouth"></div>
        </div>
        <div class="band"><span class="strip"></span><span class="knot"></span><span class="tail t1"></span><span class="tail t2"></span></div>
      </div>
    </div>
  </div>
</div></body></html>''';
}
