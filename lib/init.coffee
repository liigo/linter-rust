module.exports =
  config:
    executablePath:
      type: 'string'
      default: 'rustc'
      description: 'Path to rust compiler (rustc)'
    cargoPath:
      type: 'string'
      default: 'cargo'
      description: 'Path to rust package manager (cargo)'

  activate: ->
    console.log 'Linter-Rust: package loaded,
                 ready to get initialized by AtomLinter.'
