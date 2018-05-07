std = 'luajit'
cache = true
codes = true
globals = {'_ENV', 'ngx'}
files['spec/'].read_globals = {
  'before_each', 'describe', 'insulate', 'it', 'after_each', 'mock'
}
unused_args = false
ignore = {}
