
type 'a log = Log : 'a -> 'a log
let create_log x = Log x