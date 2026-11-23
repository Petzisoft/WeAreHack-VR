"""HACK-MONSTER: Kopie von grafik-test/monster_erzeugen.py (gleiches Modell, gleicher Stil), nur Ablage und Stilzuordnung angepasst.
Erzeugt Monsterbilder über die lokale ComfyUI-API (Krea2 turbo) und stellt sie frei (BiRefNet).
Aufruf: python monster_erzeugen.py <port> <liste.txt> [varianten]
liste.txt: pro Zeile  name|englische Beschreibung
Ergebnis: <name>_<n>.png (freigestellt, mit Transparenz) im ComfyUI-Ausgabeordner.
"""
import json, sys, time, random, urllib.request

PORT, LISTE = sys.argv[1], sys.argv[2]
VARIANTEN = int(sys.argv[3]) if len(sys.argv) > 3 else 5
import os, shutil, glob
HIER = os.path.dirname(os.path.abspath(__file__))
AUSGABE = os.path.join(HIER, 'bilder')          # freigestellt
ROH = os.path.join(HIER, 'roh')                  # mit grauem Hintergrund
C_OUT = 'C:/Users/admin/AppData/Local/Comfy-Desktop/ComfyUI-Shared/output/'


def heimholen():
    for ordner, ziel in (('hack_monster', AUSGABE), ('hack_monster_roh', ROH)):
        os.makedirs(ziel, exist_ok=True)
        for p in glob.glob(C_OUT + ordner + '/*'):
            shutil.copy2(p, os.path.join(ziel, os.path.basename(p)))
            for _ in range(5):
                try:
                    os.remove(p); break
                except PermissionError:
                    time.sleep(1)


# Aufrechte Figuren streng gerade (Peter 22.11.: "Roben müssen am Boden aufliegen, sonst ist die Figur kaputt")
STIL = ("full body shot of a {b}, standing perfectly upright, straight frontal view, camera at waist height, orthographic, no perspective distortion, "
        "both feet flat on the ground and fully visible, the hem of any robe, gown or cloak ends at the ankles and does not trail on the floor, "
        "arms close to the body, nothing pointing towards the camera, entire figure visible from head to feet, "
        "centered with a wide empty margin on all sides so that nothing is cut off, dark fantasy horror creature, photorealistic, highly detailed, "
        "menacing and scary, isolated on a plain flat light grey studio background, no text, no frame")


STIL_FLUG = ("full body shot of a {b}, flying in the air, facing the viewer, the entire creature including both wingtips visible, "
             "small in the frame and centered with a wide empty margin on all sides so that nothing is cut off, dark fantasy horror creature, photorealistic, highly detailed, cinematic dramatic lighting, "
             "menacing and scary, isolated on a plain flat light grey studio background, no text, no frame")
FLIEGER = ("k_", "x_")
STIL_TIER = ("full view of a {b}, the whole creature visible, it is NOT humanoid: no human body, no human face, no arms, no legs, "
             "centered with a wide empty margin on all sides so that nothing is cut off, dark fantasy horror creature, photorealistic, "
             "highly detailed, cinematic dramatic lighting, menacing and scary, isolated on a plain flat light grey studio background, no text, no frame")
TIERE = ("b_", "j_", "R_", "E_", "M_", "a_", "y_", "f_", "p_", "q_", "v_", "g_", "F_", "w_", "Tilde_", "Komma_", "P_")  # b_: Peter 22.11.: Käfer auf allen 6 Beinen; j_: Peter 22.11. (Jaguar als Vierbeiner); R_: Rostmonster flach (Peter 22.11.)
STIL_BEGLEITER = ("full body shot of a {b}, facing the viewer, entire animal visible from head to paws, "
                  "centered with a wide empty margin on all sides so that nothing is cut off, dark fantasy dungeon atmosphere, photorealistic, highly detailed, cinematic dramatic lighting, "
                  "gritty and realistic, isolated on a plain flat light grey studio background, no text, no frame")
BEGLEITER = ("d1_",)
# Hunde im Dreiviertel-Seitenblick, sonst erfindet TRELLIS beim 3D den Rücken als Zackenkamm (Peter 22.11.)
SEITE = ("d1_", "d2_", "d3_")
SEITENBLICK = ", seen in a three-quarter side view from the front left, the whole body including the back, flanks, hind legs and tail clearly visible, entire animal visible from nose to tail with a wide empty margin"  # Peter 21.11. 10:01: Dackel nett, nicht gruselig
# W (Geist) und P (Phantom) schweben, nutzen aber den normalen Stil


def graph(text, seed, name):
    return {
        "1": {"class_type": "UNETLoader", "inputs": {"unet_name": "krea2_turbo_fp8_scaled.safetensors", "weight_dtype": "default"}},
        "2": {"class_type": "CLIPLoader", "inputs": {"clip_name": "qwen3vl_4b_fp8_scaled.safetensors", "type": "krea2", "device": "default"}},
        "3": {"class_type": "VAELoader", "inputs": {"vae_name": "qwen_image_vae.safetensors"}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"text": text, "clip": ["2", 0]}},
        "5": {"class_type": "ConditioningZeroOut", "inputs": {"conditioning": ["4", 0]}},
        "6": {"class_type": "EmptySD3LatentImage", "inputs": {"width": 896, "height": 1152, "batch_size": 1}},
        "7": {"class_type": "KSampler", "inputs": {"model": ["1", 0], "positive": ["4", 0], "negative": ["5", 0], "latent_image": ["6", 0],
                                                    "seed": seed, "steps": 8, "cfg": 1.0, "sampler_name": "euler", "scheduler": "simple", "denoise": 1.0}},
        "8": {"class_type": "VAEDecode", "inputs": {"samples": ["7", 0], "vae": ["3", 0]}},
        "9": {"class_type": "LoadBackgroundRemovalModel", "inputs": {"bg_removal_name": "birefnet.safetensors"}},
        "10": {"class_type": "RemoveBackground", "inputs": {"image": ["8", 0], "bg_removal_model": ["9", 0]}},
        "11": {"class_type": "JoinImageWithAlpha", "inputs": {"image": ["8", 0], "alpha": ["12", 0]}},
        "12": {"class_type": "InvertMask", "inputs": {"mask": ["10", 0]}},
        "13": {"class_type": "SaveImage", "inputs": {"images": ["11", 0], "filename_prefix": "hack_monster/" + name}},
        "14": {"class_type": "SaveImage", "inputs": {"images": ["8", 0], "filename_prefix": "hack_monster_roh/" + name}},
    }


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


NUR = sys.argv[4].split(',') if len(sys.argv) > 4 else None
for zeile in open(LISTE, encoding="utf8"):
    if "|" not in zeile:
        continue
    name, beschr = [s.strip() for s in zeile.split("|", 1)]
    if NUR and name not in NUR:
        continue
    import glob, os
    nummern = [int(os.path.basename(f)[len(name) + 1:].split('_')[0]) for f in
               glob.glob(os.path.join(AUSGABE, name + '_*_00001_.png')) + glob.glob(os.path.join(HIER, 'aussortiert', name + '_*_00001_.png'))
               if os.path.basename(f)[len(name) + 1:].split('_')[0].isdigit()]
    start = max(nummern, default=0)
    for v in range(start, start + VARIANTEN):
        pid = schicke(graph((STIL_BEGLEITER if name.startswith(BEGLEITER) else STIL_FLUG if name.startswith(FLIEGER) else STIL_TIER if name.startswith(TIERE) else STIL).format(b=beschr + (SEITENBLICK if name.startswith(SEITE) else "")), random.randint(1, 2**40), f"{name}_{v + 1}"))
        print(name, v + 1, *warte(pid), flush=True)
        heimholen()
