module Precompile2

using Precompile1
test() = Precompile1.Foo((b=1, a=2)).nt

end # module
