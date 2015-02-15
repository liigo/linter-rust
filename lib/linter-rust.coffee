linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"

{exec} = require 'child_process'
{log, warn, findFile} = require "#{linterPath}/lib/utils"
path = require 'path'


class LinterRust extends Linter
  @enabled: false
  @syntax: 'source.rust'
  @rustPath: 'rustc'
  @cargoPath: 'cargo'
  @cargoManifestPath: null
  linterName: 'rust'
  errorStream: 'stderr'
  regex: '^(?<file>.+):(?<line>\\d+):(?<col>\\d+):\\s*(\\d+):(\\d+)\\s+((?<error>error|fatal error)|(?<warning>warning)):\\s+(?<message>.+)\n'

  constructor: (@editor) ->
    super @editor
    atom.config.observe 'linter-rust.executablePath', =>
      @rustPath = atom.config.get 'linter-rust.executablePath'
      exec "#{@rustPath} --version", @executionCheckHandler
    atom.config.observe 'linter-rust.cargoPath', =>
      @cargoPath = atom.config.get 'linter-rust.cargoPath'
      exec "#{@cargoPath} --version", @executionCheckHandler

  executionCheckHandler: (error, stdout, stderr) =>
    versionRegEx = /(rustc|cargo) ([\d\.]+)/
    if not versionRegEx.test(stdout)
      result = if error? then '#' + error.code + ': ' else ''
      result += 'stdout: ' + stdout if stdout.length > 0
      result += 'stderr: ' + stderr if stderr.length > 0
      console.error "Linter-Rust: `\"#{error.cmd}\"` failed:\n\
      \"#{result}\".\nPlease, check executable path in the linter settings."
    else
      @enabled = true
      log "Linter-Rust: found " + stdout

  initCmd: (editing_file) =>
    # search for Cargo.toml in container directoies
    dir = path.dirname editing_file
    @cargoManifestPath = findFile(dir, "Cargo.toml")
    if @cargoManifestPath
      log "Linter-Rust: found Cargo.toml: #{@cargoManifestPath}"
      @cmd = "#{@cargoPath}"
      @cwd = path.dirname @cargoManifestPath
    else
      @cmd = "#{@rustPath} --no-trans --color never"#{filePath}
      @cwd = path.dirname editing_file

  lintFile: (filePath, callback) =>
    if not @enabled
      return
    # filePath is in tmp dir, not the real one that user is editing
    editing_file = @editor.getPath()
    @initCmd editing_file
    if @cargoManifestPath
      log "Linter-Rust: linting #{filePath} via cargo: #{editing_file}"
      super('build', callback)
    else
      log "Linter-Rust: linting #{filePath}"
      super(filePath, callback)

  formatMessage: (match) ->
    type = if match.error then match.error else match.warning
    "#{type}: #{match.message}"

module.exports = LinterRust
