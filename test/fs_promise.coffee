chai = require 'chai'
expect = chai.expect
_ = require 'lodash'

file_ops_promise = require '../fs_promise.coffee'
f = file_ops_promise

path_join = f.path.join

sandbox_dir = path_join __dirname, 'sandbox'
file_path_in_sandbox = path_join sandbox_dir, 'sand.txt'
text_contents_in_sandbox = """
Lorem ipsum
This is test in sandbox
"""

describe 'ensureExistDir', ()->
  it 'should ensure that sandbox dir exists', ()->
    f.ensureExistDir(sandbox_dir).then (result)->
      expect(result).to.satisfy (data)-> _.find [
        'EEXIST'
        "created: #{sandbox_dir}"
      ], (item)-> item == data
  it 'should be dir', ()->
    f.isDir(sandbox_dir).then (result)->
      expect(result).to.equal(undefined)
  it 'should not be file', ()->
    f.isFile(sandbox_dir).catch (error)->
      expect(error).to.equal("not file: #{sandbox_dir}")

describe 'write and read as utf8', ()->
  it 'should write file contents to file path', ()->
    f.write(file_path_in_sandbox, text_contents_in_sandbox).then (result)->
      expect(result).to.equal("wrote: #{file_path_in_sandbox}")
  it 'should be equal to writen contents by read', ()->
    f.read(file_path_in_sandbox).then (result)->
      expect(result).to.equal(text_contents_in_sandbox)

describe 'isFile', ()->
  it 'should be resolved if file exists', ()->
    f.isFile(file_path_in_sandbox).then (result)->
      expect(result).to.equal undefined
  it 'should be rejected if file doesnt exists', ()->
    not_exist = path_join sandbox_dir, 'not_exists.txt'
    f.isFile(not_exist).catch (error)->
      expect(error).to.match /.+ ENOENT: .+/

describe 'delete_file', ()->
  it 'should delete file if exists', ()->
    f.delete_file(file_path_in_sandbox).then (result)->
      expect(result).to.equal(undefined)

  it 'should resolve with message if file doesnt exist', ()->
    not_exist = path_join sandbox_dir, 'not_exists.txt'
    f.delete_file(not_exist).then (result)->
      expect(result.code).to.equal("ENOENT")




