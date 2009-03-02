def project_root(*args)
  path = [File.dirname(__FILE__)]
  while !File.exist?(File.join(path, 'lib', 'doodle.rb'))
    path << '..'
  end
  path = path.push(*args)
  File.expand_path(File.join(*path))
end
$:.unshift(project_root('lib'))
