/* Fixture: several assignment contexts that should each trip
 * shadowed-special-vars. */

result = 5
say result

do rc = 1 to 3
   say rc
end

x = 10
say x

/* PARSE UPPER ARG and PARSE UPPER PULL, abbreviated and explicit */
arg rc
parse upper arg rc
pull result
parse upper pull result

/* Other PARSE forms */
parse arg rc
parse pull result
parse upper value 'a' with rc
parse upper var x result
parse lower var x rc
parse caseless upper var x result
parse upper linein sigl

/* Not assignments, but still warned: EXPOSE and DROP */
call sub
exit

sub: procedure expose rc
   drop result
   return
