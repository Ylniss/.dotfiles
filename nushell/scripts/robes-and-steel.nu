def "rns imgprocess" [file: string] {
  dotnet run $"($env.REPO)/rglk/scripts/process_image.cs" $file
}
