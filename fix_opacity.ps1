Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match '\.withOpacity\(') {
        $newContent = $content -replace '\.withOpacity\(', '.withValues(alpha: '
        Set-Content -Path $_.FullName -Value $newContent -NoNewline
        Write-Output "Updated: $($_.FullName)"
    }
}
