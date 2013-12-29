local cwtest = require "cwtest"
local deque = require "deque"

local T = cwtest.new()

T:start("deque"); do
  local q = deque.new()
  T:eq( q:length(), 0 )
  T:eq( q:is_empty(), true )
  T:eq( q:contents(), {} )
  q:push_right(3)
  q:push_right(4)
  q:push_left(2)
  q:push_right(5)
  q:push_left(1)
  T:eq( q:length(), 5 )
  T:eq( q:is_empty(), false )
  T:eq( q:contents(), {1, 2, 3, 4, 5} )
  T:eq( q:pop_right(), 5 )
  T:eq( q:peek_right(), 4 )
  T:eq( q:pop_left(), 1 )
  T:eq( q:peek_left(), 2 )
  T:eq( q:contents(), {2, 3, 4} )
  q:rotate_right()
  T:eq( q:contents(), {4, 2, 3} )
  q:rotate_left(4)
  T:eq( q:contents(), {2, 3, 4} )
  q:rotate_right(2)
  T:eq( q:contents(), {3, 4, 2} )
  T:eq( q:remove_right(6), false )
  T:eq( q:remove_right(2), true )
  q:push_right(3)
  q:push_left(4)
  q:push_right(4)
  T:eq( q:contents(), {4, 3, 4, 3, 4} )
  T:eq( q:remove_right(3), true )
  T:eq( q:remove_left(4), true )
  T:eq( q:contents(), {3, 4, 4} )
  local t = {}
  for x in q:iter_left() do t[#t+1] = x end
  T:eq( t, {3, 4, 4} )
  t = {}
  for x in q:iter_right() do t[#t+1] = x end
  T:eq( t, {4, 4, 3} )
end; T:done()
