local printf = function(p,...)
  io.stdout:write(string.format(p,...)); io.stdout:flush()
end

return {
  printf = printf,
}
