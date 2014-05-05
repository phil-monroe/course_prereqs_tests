require 'matrix'
require 'benchmark'

N_USERS = 200
N_CLASSES = 100

a = Matrix.build(N_USERS, N_CLASSES) {|row, col| rand(2) }
a_t = a.transpose

# puts (a_t * a).inspect
n = 10
Benchmark.bm(7) do |x|
  x.report("matrix multiplication")   { n.times { a_t * a }   }
end