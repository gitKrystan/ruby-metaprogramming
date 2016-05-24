# CallCounter

CallCounter is a ruby library that will modify an existing program to output the number of times a specific method is called.

### To Use

Set a COUNT_CALLS_TO environment variable to a string identifying the target method. Valid method signatures include:
* `Array#map!`
* `ActiveRecord::Base#find`
* `Base64.encode64`

Require `khm_solution` at the top of the host program, or via ruby's -r flag (i.e. `ruby -r ./khm_solution.rb host_program.rb`).

##### Examples

An existing class and method:
```
$ COUNT_CALLS_TO='String#size' ruby -r ./khm_solution.rb -e '(1..100).each{|i| i.to_s.size if i.odd? }'
# String#size called 50 times
```

A new class that inherits a method from a module:
```
$ COUNT_CALLS_TO='B#foo' ruby -r ./khm_solution.rb -e 'module A; def foo; end; end; class B; include A; end; 10.times{B.new.foo}'
# B#foo called 10 times
```

A new class that inherits a method from a module. CallCounter does not count calls from another class that inherits the same method:
```
$ COUNT_CALLS_TO='C#foo' ruby -r ./khm_solution.rb -e 'module A; end; module B; def foo; end; end; class C; include(A, B); end; class D; include(A, B); end; 2.times{C.new.foo; D.new.foo}'
# C#foo called 2 times
```

### Tests!
Covered with unit and acceptance tests (for CLI). Run em with `rspec`. (`bundle install` first)
