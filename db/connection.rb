require "pg"

$db = PG.connect({
  dbname: 'transhumanity'
})
