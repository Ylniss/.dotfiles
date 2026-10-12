def "rns process-image" [file: string] {
  dotnet run $"($env.REPO)/rglk/scripts/process_image.cs" $file
}
