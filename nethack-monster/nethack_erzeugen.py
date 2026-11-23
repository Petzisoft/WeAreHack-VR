"""NETHACK-MONSTER: gleiches System wie die Rogue- und Hack-Monster (Krea 2 Turbo + BiRefNet, Prompt-Stil aus
grafik-test/monster_erzeugen.py); Frauen (Stil W) wie Medusa/Nymphe mit Z-Image Turbo (Apache 2.0).
Aufruf: python -E nethack_erzeugen.py <port> <varianten> [Schlüssel,Schlüssel,...|KLASSE:ANT,DOG]
Liste: nethack_texte.txt  (Klasse|Schlüssel|Stil|Deutsch|Bildtext)
Ergebnis: bilder/<Schlüssel>_<n>_00001_.png (freigestellt), roh/... (grauer Hintergrund).
Vorhandene Nummern (auch in aussortiert/) werden fortgezählt.
"""
import glob, json, os, random, shutil, sys, time, urllib.request

PORT = sys.argv[1] if len(sys.argv) > 1 else "8188"
VARIANTEN = int(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[2].isdigit() else 3
AUSWAHL = sys.argv[3] if len(sys.argv) > 3 else ""
HIER = os.path.dirname(os.path.abspath(__file__))
AUSGABE, ROH = os.path.join(HIER, 'bilder'), os.path.join(HIER, 'roh')
C_OUT = 'C:/Users/admin/AppData/Local/Comfy-Desktop/ComfyUI-Shared/output/'
PRAEFIX = 'nethack_monster'

STIL = {
    "S": None,   # wird unten auf "A" gesetzt: aufrechte Figuren immer streng gerade (Peter 22.11.)
    "F": ("full body shot of a {b}, flying in the air, facing the viewer, the entire creature including both wingtips visible, "
          "small in the frame and centered with a wide empty margin on all sides so that nothing is cut off, dark fantasy horror creature, photorealistic, highly detailed, cinematic dramatic lighting, "
          "menacing and scary, isolated on a plain flat light grey studio background, no text, no frame"),
    # V = Vierbeiner im Dreiviertel-Seitenblick: frontal erfindet TRELLIS den unsichtbaren Rücken oft als Zackenkamm (Peter 22.11.)
    "V": ("full body shot of a {b}, seen in a three-quarter side view from the front left, the whole body including the back, flanks, hind legs and tail clearly visible, "
          "entire animal visible from nose to tail, centered with a wide empty margin on all sides so that nothing is cut off, dark fantasy horror creature, photorealistic, highly detailed, cinematic dramatic lighting, "
          "menacing and scary, isolated on a plain flat light grey studio background, no text, no frame"),
    # A = aufrecht stehend, streng (Peter 22.11.: "Roben müssen am Boden aufliegen, sonst ist die Figur kaputt"): TRELLIS baut aus
    # Bildern mit Kamera von oben oder Schleppe schiefe Figuren, deshalb gerade, auf Hüfthöhe, Saum über den Knöcheln
    "A": ("full body shot of a {b}, standing perfectly upright, straight frontal view, camera at waist height, orthographic, no perspective distortion, "
          "both feet flat on the ground and fully visible, the hem of any robe, gown or cloak ends at the ankles and does not trail on the floor, "
          "arms close to the body, nothing pointing towards the camera, entire figure visible from head to feet, centered with a wide empty margin on all sides so that nothing is cut off, "
          "dark fantasy, photorealistic, highly detailed, even soft lighting, isolated on a plain flat light grey studio background, no text, no frame"),
    "T": ("full view of a {b}, the whole creature visible, it is NOT humanoid: no human body, no human face, no arms, no legs, "
          "centered with a wide empty margin on all sides so that nothing is cut off, dark fantasy horror creature, photorealistic, "
          "highly detailed, cinematic dramatic lighting, menacing and scary, isolated on a plain flat light grey studio background, no text, no frame"),
}
STIL["S"] = STIL["A"]
# Frauen wie grafik-test/zimage_erzeugen.py (Medusa/Nymphe)
FIGUREN = [
    "buxom curvaceous amazon warrior physique, extremely busty with gigantic double-D breasts and ample cleavage, tiny waist, wide hips",
    "voluptuous classic fantasy body, huge round breasts pushed up by the top with deep cleavage, very slim waist, long legs",
    "hourglass figure with an oversized bust, massive breasts straining the top, deep cleavage, narrow waist, thick thighs",
]
FRAU = ("full body shot of {b}, {figur}, menacing seductive pose, fully clothed, the clothing covers her breasts completely, standing, the entire figure visible from the top of her head to her feet including both feet, "
        "wide empty margin on all sides. Real and terrifying: photorealistic dark fantasy horror, like a still from a live-action film, "
        "realistic skin texture, cold predatory stare, dramatic moody lighting, not a cartoon, not a comic, "
        "isolated on a plain flat light grey studio background, no text")


def freistellen(g, bild, name):
    g.update({
        "90": {"class_type": "LoadBackgroundRemovalModel", "inputs": {"bg_removal_name": "birefnet.safetensors"}},
        "91": {"class_type": "RemoveBackground", "inputs": {"image": bild, "bg_removal_model": ["90", 0]}},
        "92": {"class_type": "InvertMask", "inputs": {"mask": ["91", 0]}},
        "93": {"class_type": "JoinImageWithAlpha", "inputs": {"image": bild, "alpha": ["92", 0]}},
        "94": {"class_type": "SaveImage", "inputs": {"images": ["93", 0], "filename_prefix": PRAEFIX + "/" + name}},
        "95": {"class_type": "SaveImage", "inputs": {"images": bild, "filename_prefix": PRAEFIX + "_roh/" + name}},
    })
    return g


def graph_krea(text, seed, name):
    return freistellen({
        "1": {"class_type": "UNETLoader", "inputs": {"unet_name": "krea2_turbo_fp8_scaled.safetensors", "weight_dtype": "default"}},
        "2": {"class_type": "CLIPLoader", "inputs": {"clip_name": "qwen3vl_4b_fp8_scaled.safetensors", "type": "krea2", "device": "default"}},
        "3": {"class_type": "VAELoader", "inputs": {"vae_name": "qwen_image_vae.safetensors"}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["2", 0]}},
        "5": {"class_type": "ConditioningZeroOut", "inputs": {"conditioning": ["4", 0]}},
        "6": {"class_type": "EmptySD3LatentImage", "inputs": {"width": 896, "height": 1152, "batch_size": 1}},
        "7": {"class_type": "KSampler", "inputs": {"model": ["1", 0], "positive": ["4", 0], "negative": ["5", 0], "latent_image": ["6", 0],
                                                    "seed": seed, "steps": 8, "cfg": 1.0, "sampler_name": "euler", "scheduler": "simple", "denoise": 1.0}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["7", 0], "vae": ["3", 0]}},
    }, ["8", 0], name)


def graph_zimage(text, seed, name):
    return freistellen({
        "1": {"class_type": "UNETLoader", "inputs": {"unet_name": "z_image_turbo_bf16.safetensors", "weight_dtype": "default"}},
        "2": {"class_type": "ModelSamplingAuraFlow", "inputs": {"model": ["1", 0], "shift": 3.0}},
        "3": {"class_type": "CLIPLoader", "inputs": {"clip_name": "qwen_3_4b.safetensors", "type": "lumina2", "device": "default"}},
        "4": {"class_type": "VAELoader", "inputs": {"vae_name": "ae.safetensors"}},
        "5": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["3", 0], "text": text}},
        "15": {"class_type": "ConditioningZeroOut", "inputs": {"conditioning": ["5", 0]}},
        "6": {"class_type": "EmptySD3LatentImage", "inputs": {"width": 832, "height": 1216, "batch_size": 1}},
        "7": {"class_type": "KSampler", "inputs": {"model": ["2", 0], "positive": ["5", 0], "negative": ["15", 0], "latent_image": ["6", 0],
                                                    "seed": seed, "steps": 9, "cfg": 1.0, "sampler_name": "res_multistep", "scheduler": "simple", "denoise": 1.0}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["7", 0], "vae": ["4", 0]}},
    }, ["8", 0], name)


def schicke(g):
    req = urllib.request.Request(f"http://127.0.0.1:{PORT}/prompt", data=json.dumps({"prompt": g}).encode(),
                                 headers={"Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(req))["prompt_id"]


def warte(pid):
    while True:
        h = json.load(urllib.request.urlopen(f"http://127.0.0.1:{PORT}/history/{pid}"))
        if pid in h:
            st = h[pid].get("status", {})
            return st.get("status_str", "?"), st.get("messages", [])[-1:] if st.get("status_str") != "success" else ""
        time.sleep(1)


def heimholen():
    for ordner, ziel in ((PRAEFIX, AUSGABE), (PRAEFIX + '_roh', ROH)):
        os.makedirs(ziel, exist_ok=True)
        for p in glob.glob(C_OUT + ordner + '/*'):
            shutil.copy2(p, os.path.join(ziel, os.path.basename(p)))
            for _ in range(5):
                try:
                    os.remove(p); break
                except PermissionError:
                    time.sleep(1)


def liste():
    # Nachträgliche Änderungen (Schlüssel|Stil|Bildtext) in texte_neu.txt überschreiben die Hauptliste; nur anhängen, damit laufende Läufe nicht gestört werden
    neu = {}
    pn = os.path.join(HIER, 'texte_neu.txt')
    if os.path.exists(pn):
        for z in open(pn, encoding='utf8'):
            if z.count('|') >= 2 and not z.startswith('#'):
                k, st, tx = [s.strip() for s in z.split('|', 2)]
                neu[k] = (st, tx)
    zeilen = open(os.path.join(HIER, 'nethack_texte.txt'), encoding='utf8').read().splitlines()
    for z in zeilen:
        if z.startswith('#') or z.count('|') < 4:
            continue
        klasse, key, stil, deutsch, text = [s.strip() for s in z.split('|', 4)]
        if key in neu:
            stil, text = neu[key]
        yield klasse, key, stil, deutsch, text


def gewaehlt(klasse, key):
    if not AUSWAHL:
        return True
    if AUSWAHL.startswith('KLASSE:'):
        return klasse in AUSWAHL[7:].split(',')
    return key in AUSWAHL.split(',')


if __name__ == '__main__':
    for klasse, key, stil, deutsch, text in liste():
        if not gewaehlt(klasse, key):
            continue
        nummern = [int(os.path.basename(f)[len(key) + 1:].split('_')[0]) for f in
                   glob.glob(os.path.join(AUSGABE, key + '_*_00001_.png')) + glob.glob(os.path.join(HIER, 'aussortiert', key + '_*_00001_.png'))
                   if os.path.basename(f)[len(key) + 1:].split('_')[0].isdigit()]
        start = max(nummern, default=0)
        for v in range(start, start + VARIANTEN):
            seed = random.randint(1, 2**40)
            if stil == "W":
                g = graph_zimage(FRAU.format(b=text, figur=FIGUREN[v % 3]), seed, f"{key}_{v + 1}")
            else:
                g = graph_krea(STIL[stil].format(b=text), seed, f"{key}_{v + 1}")
            print(key, v + 1, *warte(schicke(g)), flush=True)
            heimholen()
