/* Fixture: same shapes as shadowed-vars-bad.rex, but with clean
 * names -- shadowed-special-vars should find nothing here. */

answer = 5
say answer

do i = 1 to 3
   say i
end

x = 10
say x
