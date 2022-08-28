
$ClojureArgs = $args -replace '{','{{' -replace '}','}}' -replace '"','\"'

powershell -c Invoke-Clojure @ClojureArgs