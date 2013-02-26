jsdom = require 'jsdom'

emblem = require 'emblem/dist/emblem'

module.exports = (grunt) ->
  description = 'Compile emblem templates into Handlebars.'

  grunt.registerMultiTask 'emblem', description, ->
    window = jsdom.jsdom().createWindow()


    options = @options()

    if options.paths.jquery
      window.run grunt.file.read options.paths.jquery, 'utf8'

    window.run grunt.file.read options.paths.handlebars, 'utf8'
    window.run grunt.file.read options.paths.emblem, 'utf8'
    if options.paths.ember
      window.run grunt.file.read options.paths.ember, 'utf8'
      emberEnabled = true
    else
      emberEnabled = false


    grunt.verbose.writeflags(options, 'Options')

    @files.forEach (f) ->
      partials = []
      templates = []

      # iterate files, processing partials and templates separately
      f.src.filter(fileExists).forEach (filepath) ->
        templates.push compileFilepath(filepath, window, options.root)

      output = partials.concat(templates)

      if output.length < 1
        grunt.log.warn "Destination not written because compiled files were empty."
      else
        writeOutput(output, f, options.separator)


  ########################################################
  ## Writes final output to destination
  ########################################################
  writeOutput = (output, file, separator) ->

    grunt.file.write file.dest, output.join(
      # grunt.util.normalizelf(separator)
    )

    grunt.log.writeln "File \"" + file.dest + "\" created."


  ########################################################
  # Compiles the file at provided filepath and returns the output
  ########################################################
  compileFilepath = (filepath, window, root) ->

    src = grunt.file.read(filepath)

    try
      key = filepath
        .replace(new RegExp('\\\\', 'g'), '/') #replace backslashes
        .replace(/\.\w+$/, '')
        .replace(root, '')

      content = window.Emblem.precompile window.Ember.Handlebars, src
      result = "Ember.TEMPLATES[#{JSON.stringify(key)}] =" +
               "Ember.Handlebars.template(#{content});" +
               "module.exports = module.id;"
    catch e
      grunt.fail.warn e
      # Warn on and remove invalid source files (if nonull was set).
      grunt.fail.warn "Emblem failed to compile " + filepath + "."
    result


  ########################################################
  # Filters out missing files
  ########################################################
  fileExists = (filepath) ->
    unless grunt.file.exists(filepath)
      grunt.log.warn "Source file \"" + filepath + "\" not found."
      false
    else
      true

