da3 auto /root/mutagen/images \
  --model-dir depth-anything/DA3NESTED-GIANT-LARGE-1.1 \
  --export-dir /root/output/ \
  --export-format colmap

ns-train splatfacto \
          colmap --data /root/output/colmap \
          --colmap-path sparse/0 \
          --downscale-factor 1
