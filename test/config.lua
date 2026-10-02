local eaw = require("eaw-abstraction-layer")

eaw.init("./mod")
eaw.use_busted()
eaw.use_real_errors(true)

return eaw
