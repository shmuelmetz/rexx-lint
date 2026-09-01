/* Fixture: several assignment contexts that should each trip
 * shadowed-special-vars. */

result = 5
say result

do rc = 1 to 3
   say rc
end

x = 10
say x
