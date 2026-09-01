/* Fixture: a real collection object with do over, and an ordinary
 * bounded loop -- should find nothing. See the check class's own
 * docstring for a known limitation this fixture deliberately does
 * NOT exercise: a stem populated by address...with output stem (a
 * legitimate, necessary use) still looks identical to array
 * simulation to this purely syntactic check, and would be flagged. */

arr = .Array~of('a', 'b', 'c')
do x over arr
   say x
end

do j = 1 to 10
   say j
end
