def "rns imgprocess" [file: string] {
  python $"($env.repo)/rglk/scripts/process_image.py" $file
}
