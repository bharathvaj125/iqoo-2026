# Kuzu 3D Asset

This project bundles Kuzu at `assets/character/kuzu.glb`.

## Update: real sculpted/textured model (Meshy AI export)

This replaces the earlier procedural (spheres/boxes) placeholder with a
properly sculpted and textured character generated from the reference
artwork using Meshy AI's Image-to-3D tool.

- **Geometry**: single textured mesh, ~10.4k triangles, ~13.7k vertices —
  light enough for smooth playback on mobile and web.
- **Textures**: base color + normal + metallic/roughness maps, resized to
  1024x1024 and encoded as WebP, embedded in the GLB.
- **File size**: reduced from the raw Meshy export (~16.5 MB) down to
  ~0.9 MB using `@gltf-transform/cli` (dedup, weld, prune, texture resize +
  WebP re-encode). Vertex/index data was **not** compressed with
  Draco/Meshopt, so no extra decoder needs to be registered by the 3D
  viewer — it loads the same way plain, uncompressed GLBs do.

### No skeleton / rig

The exported mesh has **no skin or bones** — it's a single rigid mesh node
(`KuzuBody`), wrapped in a `KuzuRoot` parent node. Getting a bone-rigged
export from Meshy requires a paid plan (or regenerating with the free
"Meshy 6 Lite" engine, which supports free rigged exports on a monthly
cap).

Because of this, the 7 animation clips your app expects —
`Idle`, `Blink`, `Talk`, `Wave`, `Happy`, `Thinking`, `Encourage` — are
implemented as **whole-body transform animations** (gentle bob, small sway,
quick bounce, slight yaw/tilt, etc.) on the `KuzuRoot` node rather than
per-limb motion. This keeps the app's existing animation-name-based code in
`companion_character.dart` working unmodified, but Kuzu will not visibly
wave an individual arm or blink individual eyes — the whole figure moves
together instead.

If you later obtain a properly rigged/animated export (via a Meshy
subscription, Meshy 6 Lite, or an artist), replace this `kuzu.glb` with
that file. As long as it keeps a similarly-named root hierarchy and the
same 7 animation clip names, no Dart code changes are needed. If its clip
names differ, update the `playAnimation(animationName: ...)` calls in
`lib/widgets/companion_character.dart` to match.

### Camera framing

`companion_character.dart`'s `setCameraTarget` / `setCameraOrbit` calls
were re-tuned for this model's bounding box (~1.9 units tall, centered near
the origin) instead of the old rig's. If Kuzu appears to be facing away
from the camera when you first run the app, the mesh's forward axis is
probably -Z instead of +Z — flip the `theta` value in
`_onModelLoad()` from `0` to `180` to correct it.

## Flutter Web requirement

The 3D viewer package requires its `model_viewer.min.js` module to be
loaded by `web/index.html`. This project includes that configuration and a
`web/flutter_bootstrap.js` file.

After extracting the project:

```powershell
flutter pub get
flutter run -d chrome
```

If Chrome still displays an old cached version, stop the running app, close
the browser tab, and run it again.
