def "rns imgprocess" [file: string] {
  dotnet run $"($env.repo)/rglk/scripts/process_image.cs" $file
}
