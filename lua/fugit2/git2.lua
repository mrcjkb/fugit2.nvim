local ffi = require "ffi"
local libgit2 = require "fugit2.libgit2"

--- Libgit2 init
local libgit2_init_count = 0

if libgit2_init_count == 0 then
  libgit2_init_count = libgit2.C.git_libgit2_init()
end


-- ========================
-- | Libgit2 Enum section |
-- ========================

local GIT_REFERENCE_STRING = {
  "INVALID",
  "DIRECT",
  "SYMBOLIC",
  "DIRECT/SYMBOLIC",
}

---@enum GIT_REFERENCE_NAMESPACE
local GIT_REFERENCE_NAMESPACE = {
  NONE   = 0, -- Normal ref, no namespace
  BRANCH = 1, -- Reference is in Branch namespace
  TAG    = 2, -- Reference is in Tag namespace
  REMOTE = 3, -- Reference is in Remote namespace
  NOTE   = 4, -- Reference is in Note namespace
}

local GIT_REFERENCE_PREFIX = {
  [GIT_REFERENCE_NAMESPACE.BRANCH] = string.len("refs/heads/") + 1,
  [GIT_REFERENCE_NAMESPACE.TAG]    = string.len("refs/tags/") + 1,
  [GIT_REFERENCE_NAMESPACE.REMOTE] = string.len("refs/remotes/") + 1,
  [GIT_REFERENCE_NAMESPACE.NOTE]   = string.len("refs/notes/") + 1,
}

local GIT_DELTA_STRING = {
  "UNMODIFIED",
  "ADDED",
  "DELETED",
  "MODIFIED",
  "RENAMED",
  "COPIED",
  "IGNORED",
  "UNTRACKED",
  "TYPECHANGE",
  "UNREADABLE",
  "CONFLICTED",
}

-- =====================
-- | Class definitions |
-- =====================

---@class GitConfig
---@field config ffi.cdata* libgit2 struct git_config*
local Config = {}
Config.__index = Config


---@class GitConfigEntry
---@field name string
---@field value string
---@field include_depth integer
---@field level GIT_CONFIG_LEVEL


---@class GitRepository
---@field repo ffi.cdata* libgit2 struct git_repository*
---@field path string git repository path
local Repository = {}
Repository.__index = Repository

---@class GitObject
---@field obj ffi.cdata* libgit2 struct git_object*
local Object = {}
Object.__index = Object

---@class GitObjectId
---@field oid ffi.cdata* libgit2 git_oid struct
local ObjectId = {}
ObjectId.__index = ObjectId

---@class GitBlob
---@field blob ffi.cdata* libgit2 struct git_blob**
local Blob = {}
Blob.__index = Blob

---@class GitTree
---@field tree ffi.cdata* libgit2.git_tree_pointer
local Tree = {}
Tree.__index = Tree

---@class GitTreeEntry
---@field entry ffi.cdata* libgit2 git_tree_entry*
local TreeEntry = {}
TreeEntry.__index = TreeEntry

---@class GitCommit
---@field commit ffi.cdata* libgit2 git_commit pointer
local Commit = {}
Commit.__index = Commit

---@class GitAnnotatedCommit
---@field commit ffi.cdata* libgit2 git_annotated_commit pointer
local AnnotatedCommit = {}
AnnotatedCommit.__index = AnnotatedCommit

---@class GitTag
---@field tag ffi.cdata* libgit2 git_tag pointer
---@field name string Git Tag name
local Tag = {}
Tag.__index = Tag

---@class GitReference
---@field ref ffi.cdata* libgit2 git_reference type
---@field name string Reference Refs full name
---@field type GIT_REFERENCE Reference type
---@field namespace GIT_REFERENCE_NAMESPACE Reference namespace if available
local Reference = {}
Reference.__index = Reference

---@class GitIndex
---@field index ffi.cdata* libgit2 struct git_index*[1]
local Index = {}
Index.__index = Index

---@class GitRemote
---@field remote ffi.cdata* libgit2 struct git_remote*[1]
---@field name string
---@field url string
---@field push_url string?
local Remote = {}
Remote.__index = Remote

---@class GitRevisionWalker
---@field repo ffi.cdata* libgit2 struct git_repository*
---@field revwalk ffi.cdata* libgit2 struct git_revwalk*[1]
local RevisionWalker = {}
RevisionWalker.__index = RevisionWalker

---@class GitSignature
---@field sign ffi.cdata* libgit2.git_signature_pointer
local Signature = {}
Signature.__index = Signature

---@class GitPatch
---@field patch ffi.cdata* libgit2 git_patch*
local Patch = {}
Patch.__index = Patch

---@class GitDiff
---@field diff ffi.cdata* libgit2 git_diff*
local Diff = {}
Diff.__index = Diff

---@class GitDiffHunk
---@field num_lines integer
---@field old_start integer
---@field old_lines integer
---@field new_start integer
---@field new_lines integer
---@field header string
local DiffHunk = {}

---@class GitDiffLine
---@field origin string
---@field old_lineno integer
---@field new_lineno integer
---@field num_lines integer
---@field content string

---@class GitRebase
---@field rebase ffi.cdata* libgit2 git_rebase* pointer
local Rebase = {}
Rebase.__index = Rebase


---@class GitRebaseOperation
---@field operation ffi.cdata* libgit2 git_rebase_operation pointer
local RebaseOperation = {}
RebaseOperation.__index = RebaseOperation


-- ========================
-- | Git config functions |
-- ========================


---Inits git config
function Config.new(git_config)
  local config = { config = libgit2.git_config_pointer(git_config) }
  setmetatable(config, Config)

  ffi.gc(config.config, libgit2.C.git_config_free)

  return config
end


---Open the global, XDG and system configuration files
---@return GitConfig?
---@return GIT_ERROR
function Config.open_default()
  local git_config = libgit2.git_config_double_pointer()

  local err = libgit2.C.git_config_open_default(git_config)
  if err ~= 0 then
    return nil, err
  end

  return Config.new(git_config[0]), 0
end


---Build a single-level focused config object from a multi-level one
---@param level GIT_CONFIG_LEVEL
---@return GitConfig?
---@return GIT_ERROR
function Config:open_level(level)
  local git_config = libgit2.git_config_double_pointer()

  local err = libgit2.C.git_config_open_level(git_config, self.config, level)
  if err ~= 0 then
    return nil, err
  end

  return Config.new(git_config[0]), 0
end


---Get the value of a long integer config variable.
---@param name string config name
---@return integer?
---@return GIT_ERROR
function Config:get_int(name)
  local out = libgit2.int64_array(1)
  local err = libgit2.C.git_config_get_int64(out, self.config, name)
  if err ~= 0 then
    return nil, 0
  end

  return tonumber(out[0]), 0
end


---Get the value of a boolean config variable.
---@param name string config name
---@return boolean?
---@return GIT_ERROR
function Config:get_bool(name)
  local out = libgit2.int_array(1)
  local err = libgit2.C.git_config_get_bool(out, self.config, name)
  if err ~= 0 then
    return nil, 0
  end

  return (out ~= 0), 0
end


---Get the value of a string config variable.
---@param name string config name
---@return string?
---@return GIT_ERROR
function Config:get_string(name)
  local buf = libgit2.git_buf()

  local err = libgit2.C.git_config_get_string_buf(buf, self.config, name)
  if err ~= 0 then
    libgit2.C.git_buf_dispose(buf)
    return nil, err
  end

  local str = ffi.string(buf[0].ptr, buf[0].size)
  libgit2.C.git_buf_dispose(buf)
  return str, 0
end


---Get all entries
---@return GitConfigEntry[]?
---@return GIT_ERROR
function Config:entries()
  local iter = libgit2.git_config_iterator_double_pointer()
  local err = libgit2.C.git_config_iterator_new(iter, self.config)
  if err ~= 0 then
    return nil, err
  end

  local git_config_entry = libgit2.git_config_entry_double_pointer()
  local entries = {}

  while libgit2.C.git_config_next(git_config_entry, iter[0]) == 0 do
    ---@type GitConfigEntry
    local entry = {
      name = ffi.string(git_config_entry[0].name),
      value = ffi.string(git_config_entry[0].value),
      include_depth = tonumber(git_config_entry[0].include_depth) or -1,
      level = tonumber(git_config_entry[0].level) or -1,
    }
    entries[#entries+1] = entry

    -- libgit2.C.git_config_entry_free(git_config_entry[0])
  end

  libgit2.C.git_config_iterator_free(iter[0])

  return entries, 0
end


-- ========================
-- | Git Object functions |
-- ========================


---@param git_object ffi.cdata* libgit2.git_object_pointer, own cdata.
---@return GitObject
function Object.new(git_object)
  local object = { obj = libgit2.git_object_pointer(git_object) }
  setmetatable(object, Object)

  ffi.gc(object.obj, libgit2.C.git_object_free)

  return object
end


-- Get the id (SHA1) of a repository object.
---@return GitObjectId
function Object:id()
  local oid = libgit2.C.git_object_id(self.obj[0])
  return ObjectId.borrow(oid)
end


-- ======================
-- | ObjectId functions |
-- ======================


---Creates new lbigit2 oid, then copy value from old oid.
---@param oid GitObjectId
---@return GitObjectId?
---@return GIT_ERROR
function ObjectId.from(oid)
  local git_object_id = libgit2.git_oid()

  local err = libgit2.C.git_oid_cpy(git_object_id, oid.oid)
  if err ~= 0 then
    return nil, err
  end

  return ObjectId.borrow(git_object_id), 0
end


---@param oid ffi.cdata* libgit2 git_oid*, borrow data
function ObjectId.borrow (oid)
  local object_id = { oid = oid }
  setmetatable(object_id, ObjectId)
  return object_id
end


---Creates a new ObjectId with the same value of the old one.
---@return GitObjectId?
---@return GIT_ERROR
function ObjectId:clone()
  return ObjectId.from(self)
end


---Sets this oid the same value as the given oid
---@param oid GitObjectId
---@return GIT_ERROR
function ObjectId:copy_from(oid)
  return libgit2.C.git_oid_cpy(self.oid, oid.oid)
end


---Copies this oid to target oid.
---@param oid GitObjectId
---@return GIT_ERROR
function ObjectId:copy_to(oid)
  return libgit2.C.git_oid_cpy(oid.oid, self.oid)
end


---@param n integer number of git id
---@return string
function ObjectId:tostring(n)
  if n < 0 or n > 40 then
    n = 40
  end

  local c_buf = libgit2.char_array(n+1)
  libgit2.C.git_oid_tostr(c_buf, n+1, self.oid)
  return ffi.string(c_buf, n)
end


---@param oid_str string hex formatted object id.
---@return boolean
function ObjectId:streq(oid_str)
  return (libgit2.C.git_oid_streq(self.oid, oid_str) == 0)
end


---@return string
function ObjectId:__tostring()
  return self:tostring(8)
end


---@param a GitObjectId
---@param b GitObjectId | string
---@return boolean
function ObjectId.__eq(a, b)
  if type(b) == "string" then
    return (libgit2.C.git_oid_streq(a.oid, b) == 0)
  end
  return (libgit2.C.git_oid_equal(a.oid, b.oid) ~= 0)
end


-- ===================
-- | Git Blob object |
-- ===================

---@param git_blob ffi.cdata* libgit2.git_blob_pointer, own cdata
---@return GitBlob
function Blob.new(git_blob)
  local blob = { blob = libgit2.git_blob_pointer(git_blob) }
  setmetatable(blob, Blob)

  ffi.gc(blob.blob, libgit2.C.git_blob_free)
  return blob
end

---@return GitObjectId
function Blob:id()
  local oid = libgit2.C.git_blob_id(self.blob)
  return ObjectId.borrow(oid)
end

---@return boolean
function Blob:is_binary()
  local ret = libgit2.C.git_blob_is_binary(self.blob)
  return ret == 1
end

---Gets a raw content of a blob.
---@return string
function Blob:content()
  local content = libgit2.C.git_blob_rawcontent(self.blob)
  local len = libgit2.C.git_blob_rawsize(self.blob)
  return ffi.string(content, len)
end


-- ============================
-- | Git Tree Entry functions |
-- ============================

---@param git_entry ffi.cdata* libgit2.git_tree_entry_pointer, own cdata
---@return GitTreeEntry
function TreeEntry.new(git_entry)
  local tree_entry = { entry = libgit2.git_tree_entry_pointer(git_entry) }
  setmetatable(tree_entry, TreeEntry)

  ffi.gc(tree_entry.entry, libgit2.C.git_tree_entry_free)
  return tree_entry
end

---@param entry ffi.cdata* libgit2.git_tree_entry_pointer, just borrow data, didn't own
---@return GitTreeEntry
function TreeEntry.borrow(entry)
  local git_tree_entry = { entry = entry }
  setmetatable(git_tree_entry, TreeEntry)
  return git_tree_entry
end

---Gets the id of the object pointed by the entry
---@return GitObjectId
function TreeEntry:id()
  local oid = libgit2.C.git_tree_entry_id(self.entry)
  return ObjectId.borrow(oid)
end

---Gets the filename of a tree entry.
---@return string
function TreeEntry:name()
  local c_name = libgit2.C.git_tree_entry_name(self.entry)
  return ffi.string(c_name)
end

---@return GIT_OBJECT
function TreeEntry:type()
  return libgit2.C.git_tree_entry_type(self.entry)
end

-- ===================
-- | Git Tree object |
-- ===================

---@param git_tree ffi.cdata* libgit2.git_tree_pointer, own cdata
---@return GitTree
function Tree.new(git_tree)
  local tree = { tree = libgit2.git_tree_pointer(git_tree) }
  setmetatable(tree, Tree)

  ffi.gc(tree.tree, libgit2.C.git_tree_free)
  return tree
end

function Tree:nentries()
  return libgit2.C.git_tree_entrycount(self.tree)
end

---Retrieves a tree entry contained in a tree
---or in any of its subtrees, given its relative path.
---@param path string
---@return GitTreeEntry?
---@return GIT_ERROR
function Tree:entry_bypath(path)
  local entry = libgit2.git_tree_entry_double_pointer()
  local err = libgit2.C.git_tree_entry_bypath(entry, self.tree, path)
  if err ~= 0 then
    return nil, err
  end
  return TreeEntry.new(entry[0]), 0
end

---Lookup a tree entry by its filename
---@param filename string
---@return GitTreeEntry?
function Tree:entry_byname(filename)
  local entry = libgit2.C.git_tree_entry_byname(self.tree, filename)
  if entry == nil then
    return nil
  end
  return TreeEntry.borrow(entry)
end

---Lookup a tree entry by SHA value.
---@param id GitObjectId
---@return GitTreeEntry?
function Tree:entry_byid(id)
  local entry = libgit2.C.git_tree_entry_byid(self.tree, id.oid)
  if entry == nil then
    return nil
  end
  return TreeEntry.borrow(entry)
end


-- ==================
-- | Git Tag object |
-- ==================

---@param git_tag ffi.cdata* libgit2.git_tag_pointer, own cdata
---@return GitTag
function Tag.new(git_tag)
  local tag = { tag = libgit2.git_tag_pointer(git_tag) }
  setmetatable(tag, Tag)

  tag.name = ffi.string(libgit2.C.git_tag_name(git_tag))
  ffi.gc(tag.tag, libgit2.C.git_tag_free)

  return tag
end


---Get the name of a tag
function Tag:__tostring()
  return self.name
end


-- =============================
-- | AnnotatedCommit functions |
-- =============================


---Init GitAnnotatedCommit
---@param git_commit ffi.cdata* libgit2.git_annotated_commit_pointer, this owns cdata.
---@return GitAnnotatedCommit
function AnnotatedCommit.new(git_commit)
  local commit = { commit = libgit2.git_annotated_commit_pointer(git_commit) }
  setmetatable(commit, AnnotatedCommit)

  ffi.gc(commit.commit, libgit2.C.git_annotated_commit_free)
  return commit
end


-- ====================
-- | Commit functions |
-- ====================


-- Init GitCommit.
---@param git_commit ffi.cdata* libgit2.git_commit_pointer, this owns the data.
---@return GitCommit
function Commit.new(git_commit)
  local commit = { commit = libgit2.git_commit_pointer(git_commit) }
  setmetatable(commit, Commit)

  -- ffi garbage collector
  ffi.gc(commit.commit, libgit2.C.git_commit_free)

  return commit
end


-- Gets the id of a commit.
---@return GitObjectId
function Commit:id()
  local git_oid = libgit2.C.git_commit_id(self.commit)
  return ObjectId.borrow(git_oid)
end


-- Gets GitCommit messages.
---@return string
function Commit:message()
  local c_char = libgit2.C.git_commit_message(self.commit)
  return vim.trim(ffi.string(c_char))
end


---@return string
function Commit:author()
  local sig = libgit2.C.git_commit_author(self.commit)
  return ffi.string(sig.name)
end


-- Gets the number of parents of this commit
---@return integer parentcount
function Commit:nparents()
  return libgit2.C.git_commit_parentcount(self.commit)
end

-- Gets the specified parent of the commit.
---@param i integer Parent index (0-based)
---@return GitCommit?
---@return GIT_ERROR
function Commit:parent(i)
  local c_commit = libgit2.git_commit_double_pointer()
  local err = libgit2.C.git_commit_parent(c_commit, self.commit, i)
  if err ~= 0 then
    return nil, err
  end

  return Commit.new(c_commit[0]), 0
end


-- Gets the oids of all parents
---@return GitObjectId[]
function Commit:parent_oids()
  local parents = {}
  local nparents = self:nparents()
  if nparents < 1 then
    return parents
  end

  for i=0,nparents-1 do
    local oid = libgit2.C.git_commit_parent_id(self.commit, i);
    parents[i+1] = ObjectId.borrow(oid)
  end

  return parents
end


-- =======================
-- | Reference functions |
-- =======================

---@param refname string
---@return GIT_REFERENCE_NAMESPACE
local function reference_name_namespace(refname)
  if vim.startswith(refname, "refs/") then
    local namespace = string.sub(refname, string.len("refs/") + 1)
    if vim.startswith(namespace, "heads/") then
      return GIT_REFERENCE_NAMESPACE.BRANCH
    elseif vim.startswith(namespace, "tags/") then
      return GIT_REFERENCE_NAMESPACE.TAG
    elseif vim.startswith(namespace, "remotes/") then
      return GIT_REFERENCE_NAMESPACE.REMOTE
    elseif vim.startswith(namespace, "notes/") then
      return GIT_REFERENCE_NAMESPACE.NOTE
    end
  end

  return GIT_REFERENCE_NAMESPACE.NONE
end


---@param refname string full refname
---@return string
local function reference_name_shorthand(refname)
  local namespace = reference_name_namespace(refname)
  if namespace ~= GIT_REFERENCE_NAMESPACE.NONE then
    return refname:sub(GIT_REFERENCE_PREFIX[namespace])
  end
  return refname
end


---@param refname string
---@return string?
local function reference_name_remote(refname)
  return refname:match("refs/remotes/(%a+)/")
end


---Creates new Reference object
---@param git_reference ffi.cdata* libgit2.git_reference_pointer, own cdata
---@return GitReference
function Reference.new(git_reference)
  local ref = {
    ref = libgit2.git_reference_pointer(git_reference),
    namespace = GIT_REFERENCE_NAMESPACE.NONE
  }
  setmetatable(ref, Reference)

  local c_name = libgit2.C.git_reference_name(ref.ref)
  ref.name = ffi.string(c_name)

  ref.namespace = reference_name_namespace(ref.name)
  ref.type = libgit2.C.git_reference_type(ref.ref)

  -- ffi garbage collector
  ffi.gc(ref.ref, libgit2.C.git_reference_free)

  return ref
end


function Reference:__tostring()
  return string.format("Git Ref (%s): %s", GIT_REFERENCE_STRING[self.type+1], self.name)
end


-- Transforms the reference name into a name "human-readable" version.
---@return string # Shorthand for ref
function Reference:shorthand()
  local c_name = libgit2.C.git_reference_shorthand(self.ref)
  return ffi.string(c_name)
end


-- Gets target for a GitReference
---@return GitObjectId?
---@return GIT_ERROR
function Reference:target()
  if self.type == libgit2.GIT_REFERENCE.SYMBOLIC then
    local resolved = libgit2.git_reference_double_pointer()

    local err = libgit2.C.git_reference_resolve(resolved, self.ref)
    if err ~= 0 then
      return nil, err
    end

    local oid = libgit2.C.git_reference_target(resolved)
    libgit2.C.git_reference_free(resolved)

    return ObjectId.borrow(oid), 0
  elseif self.type ~= 0 then
    local oid = libgit2.C.git_reference_target(self.ref)
    return ObjectId.borrow(oid), 0
  end

  return nil, 0
end


-- Recursively peel reference until object of the specified type is found.
---@param type GIT_OBJECT
---@return GitObject?
---@return integer Git Error code
function Reference:peel(type)
  local c_object = libgit2.git_object_double_pointer()

  local err = libgit2.C.git_reference_peel(c_object, self.ref, type);
  if err ~= 0 then
    return nil, err
  end

  return Object.new(c_object[0]), 0
end


-- Recursively peel reference until commit object is found.
---@return GitCommit?
---@return GIT_ERROR err libgit2 Error code
function Reference:peel_commit()
  local c_object = libgit2.git_object_double_pointer()

  local err = libgit2.C.git_reference_peel(c_object, self.ref, libgit2.GIT_OBJECT.COMMIT)
  if err ~= 0 then
    return nil, err
  end

  return Commit.new(ffi.cast(libgit2.git_commit_pointer, c_object[0])), 0
end


---Recursively peel reference until tree object is found.
---@return GitTree?
---@return GIT_ERROR err libgit2 Error code
function Reference:peel_tree()
  local c_object = libgit2.git_object_double_pointer()

  local err = libgit2.C.git_reference_peel(c_object, self.ref, libgit2.GIT_OBJECT.TREE)
  if err ~= 0 then
    return nil, err
  end

  return Tree.new(ffi.cast(libgit2.git_tree_pointer, c_object[0])), 0
end


---Gets upstream for a branch.
---@return GitReference? Reference git upstream reference
---@return GIT_ERROR
function Reference:branch_upstream()
  if self.namespace ~= GIT_REFERENCE_NAMESPACE.BRANCH then
    return nil, 0
  end

  local c_ref = libgit2.git_reference_double_pointer()
  local err = libgit2.C.git_branch_upstream(c_ref, self.ref);
  if err ~= 0 then
    return nil, err
  end

  return Reference.new(c_ref[0]), 0
end


---Retrieves the upstream remote name of a remote_reference.
---@return string?
function Reference:remote_name()
  if self.namespace == GIT_REFERENCE_NAMESPACE.REMOTE then
    return self.name:match("remotes/([^/]+)/", 6)
  end
end

---Get full name to the reference pointed to by a symbolic reference.
---@return string?
function Reference:symbolic_target()
  if bit.band(self.type, libgit2.GIT_REFERENCE.SYMBOLIC) ~= 0 then
    return ffi.string(libgit2.C.git_reference_symbolic_target(self.ref))
  end
end


-- ============================
-- | RevisionWalker functions |
-- ============================


-- Inits new GitRevisionWalker object.
---@param repo ffi.cdata* libgit2.git_respository_pointer, don't own data
---@param revwalk ffi.cdata* libgit2.git_revwalk_pointer, own cdata
---@return GitRevisionWalker
function RevisionWalker.new(repo, revwalk)
  local git_walker = {
    repo = libgit2.git_repository_pointer(repo),
    revwalk = libgit2.git_revwalk_pointer(revwalk)
  }
  setmetatable(git_walker, RevisionWalker)

  ffi.gc(git_walker.revwalk, libgit2.C.git_revwalk_free)
  return git_walker
end

---@return GIT_ERROR
function RevisionWalker:reset()
  return libgit2.C.git_revwalk_reset(self.revwalk)
end

---@param topo boolean sort in topo order
---@param time boolean sort by time
---@param reverse boolean reverse
---@return GIT_ERROR
function RevisionWalker:sort(topo, time, reverse)
  if not (topo or time or reverse) then
    return 0
  end

  local mode = 0ULL
  if topo then
    mode = bit.bor(mode, libgit2.GIT_SORT.TOPOLOGICAL)
  end
  if time then
    mode = bit.bor(mode, libgit2.GIT_SORT.TIME)
  end
  if reverse then
    mode = bit.bor(mode, libgit2.GIT_SORT.REVERSE)
  end

  return libgit2.C.git_revwalk_sorting(self.revwalk, mode);
end


---@param oid GitObjectId
---@return GIT_ERROR
function RevisionWalker:push(oid)
  return libgit2.C.git_revwalk_push(self.revwalk, oid.oid)
end


---@return GIT_ERROR
function RevisionWalker:push_head()
  return libgit2.C.git_revwalk_push_head(self.revwalk)
end


-- Push matching references
---@param glob string
---@return GIT_ERROR
function RevisionWalker:push_glob(glob)
  return libgit2.C.git_revwalk_push_glob(self.revwalk, glob)
end


-- Push the OID pointed to by a reference
---@param refname string
---@return GIT_ERROR
function RevisionWalker:push_ref(refname)
  return libgit2.C.git_revwalk_push_ref(self.revwalk, refname)
end


---@param oid GitObjectId
---@return GIT_ERROR
function RevisionWalker:hide(oid)
  return libgit2.C.git_revwalk_hide(self.revwalk, oid.oid)
end


---@return fun(): GitObjectId?, GitCommit?
function RevisionWalker:iter()
  local git_oid = libgit2.git_oid()

  return function()
    local err = libgit2.C.git_revwalk_next(git_oid, self.revwalk)
    if err ~= 0 then
      return nil, nil
    end

    local c_commit = libgit2.git_commit_double_pointer()
    err = libgit2.C.git_commit_lookup(c_commit, self.repo, git_oid)
    if err ~= 0 then
      return nil, nil
    end

    return ObjectId.borrow(git_oid), Commit.new(c_commit[0])
  end
end


-- ====================
-- | Remote functions |
-- ====================


-- Inits new GitRemote object.
---@param git_remote ffi.cdata* libgit2.git_remote_pointer, own data
---@return GitRemote
function Remote.new(git_remote)
  local remote = { remote = libgit2.git_remote_pointer(git_remote) }
  setmetatable(remote, Remote)

  remote.name = ffi.string(libgit2.C.git_remote_name(remote.remote))
  remote.url = ffi.string(libgit2.C.git_remote_url(remote.remote))
  local push_url = libgit2.C.git_remote_pushurl(remote.remote)
  if push_url ~= nil then
    remote.push_url = ffi.string(push_url)
  end

  ffi.gc(remote.remote, libgit2.C.git_remote_free)

  return remote
end


-- =======================
-- | Signature functions |
-- =======================


---@param git_signature ffi.cdata* libgit2.git_signature_pointer, own data
function Signature.new(git_signature)
  local signature = { sign = libgit2.git_signature_pointer(git_signature) }
  setmetatable(signature, Signature)

  ffi.gc(signature.sign, libgit2.C.git_signature_free)
  return signature
end


---@return string
function Signature:name()
  return ffi.string(self.sign["name"])
end


---@return string
function Signature:email()
  return ffi.string(self.sign["email"])
end


function Signature:__tostring()
  return string.format("%s <%s>", self:name(), self:email())
end


-- ===================
-- | Index functions |
-- ===================


-- Inits new GitIndex object.
---@param git_index ffi.cdata* libgit2.git_index_pointer, own cdata
---@return GitIndex
function Index.new(git_index)
  local index = { index = libgit2.git_index_pointer(git_index) }
  setmetatable(index, Index)

  ffi.gc(index.index, libgit2.C.git_index_free)

  return index
end


-- Gets the count of entries currently in the index
---@return integer
function Index:nentry()
  local entrycount = libgit2.C.git_index_entrycount(self.index)
  return math.floor(tonumber(entrycount) or -1)
end


-- Updates the contents of an existing index object.
---@param force boolean Performs hard read or not?
---@return GIT_ERROR
function Index:read (force)
  return libgit2.C.git_index_read(self.index, force and 1 or 0)
end


-- Writes index from memory to file.
---@return GIT_ERROR
function Index:write()
  return libgit2.C.git_index_write(self.index)
end


-- Write the index as a tree
---@return GitObjectId?
---@return GIT_ERROR
function Index:write_tree()
  local tree_oid = libgit2.git_oid()
  local err = libgit2.C.git_index_write_tree(tree_oid, self.index);
  if err ~= 0 then
    return nil, err
  end
  return ObjectId.borrow(tree_oid), 0
end


-- Adds path to index.
---@param path string File path to be added.
---@return GIT_ERROR
function Index:add_bypath(path)
  return libgit2.C.git_index_add_bypath(self.index, path)
end


-- Removes path from index.
---@param path string File path to be removed.
---@return GIT_ERROR
function Index:remove_bypath(path)
  return libgit2.C.git_index_remove_bypath(self.index, path)
end


-- Determine if the index contains entries representing file conflicts.
---@return boolean has_conflicts
function Index:has_conflicts()
  return (libgit2.C.git_index_has_conflicts(self.index) > 0)
end


---@param path string
---@param stage_number GIT_INDEX_STAGE
---@return { file_size: integer, id: GitObjectId, path: string }?
function Index:get_bypath(path, stage_number)
  local entry = libgit2.C.git_index_get_bypath(self.index, path, stage_number)
  if entry == nil then
    return nil
  end

  -- TODO: check this
  local oid = libgit2.git_oid({ entry.id })
  return {
    file_size = tonumber(entry.file_size),
    path      = ffi.string(entry.path),
    id        = ObjectId.borrow(oid),
  }
end

-- ==================
-- | Diff functions |
-- ==================

---Create new GitDiff object
---@param git_diff ffi.cdata* libgit2.git_diff_pointer, own cdata
---@return GitDiff
function Diff.new(git_diff)
  local diff = { diff = libgit2.git_diff_pointer(git_diff) }
  setmetatable(diff, Diff)

  ffi.gc(diff.diff, libgit2.C.git_diff_free)

  return diff
end

---@parm diff_str string
---@return GitDiff?
---@return GIT_ERROR
function Diff.from_buffer(diff_str)
  local diff = libgit2.git_diff_double_pointer()

  local err = libgit2.C.git_diff_from_buffer(diff, diff_str, diff_str:len())
  if err ~= 0 then
    return nil, err
  end

  return Diff.new(diff[0]), 0
end

---@param format GIT_DIFF_FORMAT
---@return string
function Diff:tostring(format)
  local buf = libgit2.git_buf()
  local err = libgit2.C.git_diff_to_buf(buf, self.diff, format)
  if err ~= 0 then
    libgit2.C.git_buf_dispose(buf)
    return ""
  end

  local diff = ffi.string(buf[0].ptr, buf[0].size)
  libgit2.C.git_buf_dispose(buf)
  return diff
end

function Diff:__tostring()
  return self:tostring(libgit2.GIT_DIFF_FORMAT.PATCH)
end

---Gets accumulate diff statistics for all patches.
---@return GitDiffStats?
---@return GIT_ERROR
function Diff:stats()
  local diff_stats = libgit2.git_diff_stats_double_pointer()
  local err = libgit2.C.git_diff_get_stats(diff_stats, self.diff);
  if err ~= 0 then
    return nil, err
  end
  ---@type GitDiffStats
  local stats = {
    changed = libgit2.C.git_diff_stats_files_changed(diff_stats[0]),
    insertions = libgit2.C.git_diff_stats_insertions(diff_stats[0]),
    deletions = libgit2.C.git_diff_stats_deletions(diff_stats[0])
  }

  libgit2.C.git_diff_stats_free(diff_stats[0]);
  return stats, 0
end

---Gets patches from diff as a list
---@param sort_case_sensitive boolean
---@return GitDiffPatchItem[]
---@return GIT_ERROR
function Diff:patches(sort_case_sensitive)
  local patches = {}
  local err = 0

  local num_deltas = tonumber(libgit2.C.git_diff_num_deltas(self.diff))
  for i=0,num_deltas-1 do
    local delta = libgit2.C.git_diff_get_delta(self.diff, i)

    local c_patch = libgit2.git_patch_double_pointer()
    err = libgit2.C.git_patch_from_diff(c_patch, self.diff, i)
    if err ~= 0 then
      break
    end

    local patch = Patch.new(c_patch[0])

    ---@type GitDiffPatchItem
    local patch_item = {
      status    = delta.status,
      path      = ffi.string(delta.old_file.path),
      new_path  = ffi.string(delta.new_file.path),
      num_hunks = patch:nhunks(),
      patch     = patch
    }

    table.insert(patches, patch_item)
  end

  if #patches > 0 and sort_case_sensitive then
    -- sort patches by name
    table.sort(patches, function (a, b)
      return a.path < b.path
    end)
  end

  return patches, err
end


-- ===================
-- | Patch functions |
-- ===================

---Creates new GitPatch object
---@param git_patch ffi.cdata* libgit2.git_patch_pointer, own cdata
---@return GitPatch
function Patch.new(git_patch)
  local patch = { patch = libgit2.git_patch_pointer(git_patch) }
  setmetatable(patch, Patch)

  ffi.gc(patch.patch, libgit2.C.git_patch_free)

  return patch
end

---Gets the content of a patch as a single diff text.
---@return string
function Patch:__tostring()
  local buf = libgit2.git_buf()
  local err = libgit2.C.git_patch_to_buf(buf, self.patch)
  if err ~= 0 then
    libgit2.C.git_buf_dispose(buf)
    return ""
  end

  local patch = ffi.string(buf[0].ptr, buf[0].size)
  libgit2.C.git_buf_dispose(buf)
  return patch
end

---@return GitDiffStats?
---@return GIT_ERROR
function Patch:stats()
  local number = libgit2.size_t_array(2)
  local err = libgit2.C.git_patch_line_stats(
    nil, number, number + 1, self.patch
  )
  if err ~= 0 then
    return nil, err
  end

  return {
    changed = 1,
    insertions = tonumber(number[0]),
    deletions = tonumber(number[1])
  }, 0
end

---Gets the number of hunks in a patch
---@return integer
function Patch:nhunks()
  return tonumber(libgit2.C.git_patch_num_hunks(self.patch)) or 0
end

---@param idx integer Hunk index 0-based
---@return GitDiffHunk?
---@return GIT_ERROR
function Patch:hunk(idx)
  local num_lines = libgit2.size_t_array(1)
  local hunk = libgit2.git_diff_hunk_double_pointer()

  local err = libgit2.C.git_patch_get_hunk(
    hunk, num_lines, self.patch, idx
  )
  if err ~= 0 then
    return nil, err
  end

  ---@type GitDiffHunk
  local diff_hunk = {
    num_lines = tonumber(num_lines[0]) or 0,
    old_start = hunk[0].old_start,
    old_lines = hunk[0].old_lines,
    new_start = hunk[0].new_start,
    new_lines = hunk[0].new_lines,
    header    = ffi.string(hunk[0].header, hunk[0].header_len)
  }

  return diff_hunk, 0
end

---@param hunk_idx integer Hunk index 0-based
---@param line_idx integer Line index in hunk, 0-based
---@return GitDiffLine?
---@return GIT_ERROR
function Patch:hunk_line(hunk_idx, line_idx)
  local diff_line = libgit2.git_diff_line_double_pointer()

  local err = libgit2.C.git_patch_get_line_in_hunk(diff_line, self.patch, hunk_idx, line_idx)
  if err ~= 0 then
    return nil, err
  end

  ---@type GitDiffLine
  local ret = {
    origin     = string.char(diff_line[0].origin),
    old_lineno = diff_line[0].old_lineno,
    new_lineno = diff_line[0].new_lineno,
    num_lines  = diff_line[0].num_lines,
    content    = ffi.string(diff_line[0].content, diff_line[0].content_len)
  }
  return ret, 0
end

---Gets the number of lines in a hunk.
---@param i integer
---@return integer
function Patch:hunk_num_lines(i)
  return libgit2.C.git_patch_num_lines_in_hunk(self.patch, i)
end


--- ============================
-- | RebaseOperation functions |
-- =============================


---Borrow new RebaseOperation
---@param operation_ptr ffi.cdata* libgit2 git_rebase_operation pointer
---@return GitRebaseOperation
function RebaseOperation.borrow(operation_ptr)
  local op = {
    operation = libgit2.git_rebase_operation_pointer(operation_ptr)
  }
  setmetatable(op, RebaseOperation)
  return op
end


---Gets type of a rebase operation
---@return GIT_REBASE_OPERATION
function RebaseOperation:type()
  return self.operation["type"]
end


---Changes type of a rebase operation.
---@param type GIT_REBASE_OPERATION
function RebaseOperation:set_type(type)
  self.operation["type"] = type
end


---Gets rebase operation exec.
---@return string
function RebaseOperation:exec()
  local str_ptr = self.operation["exec"]
  return str_ptr ~= nil and ffi.string(str_ptr) or ""
end


---Sets rebase operation exec string
---@param exec string
function RebaseOperation:set_exec(exec)
  self.operation["exec"] = exec
end


---Gets ObjectId of rebase operation.
---@return GitObjectId
function RebaseOperation:id()
  return ObjectId.borrow(
    ffi.cast(libgit2.git_oid_pointer, self.operation["id"])
  )
end


---Copies another git_oid to this RebaseOperation oid.
---@param oid GitObjectId
---@return GIT_ERROR err 0 on success or error code
function RebaseOperation:set_id(oid)
  local op_id_ptr = ffi.cast(libgit2.git_oid_pointer, self.operation["id"])
  return libgit2.C.git_oid_cpy(op_id_ptr, oid.oid)
end


-- ====================
-- | Rebase functions |
-- ====================


---Init new Gitrebase
---@param git_rebase_ptr ffi.cdata* libgit2 git_rebase*, own cdata
---@return GitRebase
function Rebase.new(git_rebase_ptr)
  local rebase = { rebase = libgit2.git_rebase_pointer(git_rebase_ptr) }
  setmetatable(rebase, Rebase)

  ffi.gc(rebase.rebase, libgit2.C.git_rebase_free)
  return rebase
end


---Pretty print current rebase operation
function Rebase:__tostring()
  local str = "Rebase "
  local onto_id = libgit2.C.git_rebase_onto_id(self.rebase)
  local org_id =  libgit2.C.git_rebase_orig_head_id(self.rebase)

  local org_str = libgit2.C.git_oid_tostr_s(org_id)
  if org_str ~= nil then
    str = str .. string.sub(ffi.string(org_str), 1, 8)
  end

  local onto_str = libgit2.C.git_oid_tostr_s(onto_id)
  if onto_str ~= nil then
    str = str .. " onto " .. string.sub(ffi.string(onto_str), 1, 8)
  end

  return str
end


---Performs the next rebase operation and returns the information about it.
---@return GitRebaseOperation?
---@return GIT_ERROR
function Rebase:next()
  local operation = libgit2.git_rebase_operation_double_pointer()
  local err = libgit2.C.git_rebase_next(operation, self.rebase)
  if err ~= 0 then
    return nil, err
  end

  return RebaseOperation.borrow(operation[0]), 0
end


---Gets the count of rebase operations that are to be applied.
---@return integer
function Rebase:noperations()
  return tonumber(libgit2.C.git_rebase_operation_entrycount(self.rebase)) or -1
end


---Gets the index of the rebase operation that is currently being applied.
---@return integer index If the first operation has not yet been applied, returns GIT_REBASE_NO_OPERATION
function Rebase:operation_current()
  return libgit2.C.git_rebase_operation_current(self.rebase)
end


---Gets the rebase operation specified by the given index.
---@return GitRebaseOperation? The rebase operation or NULL if `idx` was out of bounds.
function Rebase:operation_byindex(idx)
  local operation = libgit2.C.git_rebase_operation_byindex(self.rebase, idx)
  if operation == nil then
    return nil
  end

  return RebaseOperation.borrow(operation)
end


---Gets the onto ref name for merge rebases.
---@return string
function Rebase:onto_name()
  local name_ptr = libgit2.C.git_rebase_onto_name(self.rebase)
  if name_ptr == nil then
    return ""
  end
  return ffi.string(name_ptr)
end


---Gets the onto id for merge rebases.
function Rebase:onto_id()
  local oid_ptr = libgit2.C.git_rebase_onto_id(self.rebase)
  return ObjectId.borrow(oid_ptr)
end


---Gets the original HEAD ref name for merge rebases.
---@return string
function Rebase:orig_head_name()
  local name_ptr = libgit2.C.git_rebase_orig_head_name(self.rebase)
  if name_ptr == nil then
    return ""
  end
  return ffi.string(name_ptr)
end


---Gets the original HEAD id for merge rebases.
---@return GitObjectId
function Rebase:orig_head_id()
  local oid_ptr = libgit2.C.git_rebase_orig_head_id(self.rebase)
  return ObjectId.borrow(oid_ptr)
end


---Aborts a rebase that is currently in progress,
---resetting the repository and working directory to their state before rebase began.
---@return GIT_ERROR
function Rebase:abort()
  return libgit2.C.git_rebase_abort(self.rebase)
end


---Commits the current patch. You must have resolved any conflicts.
---@param author GitSignature? The author of the updated commit, or NULL to keep the author from the original commit
---@param commiter GitSignature The committer of the rebase
---@param message string? The message for this commit, or NULL to use the message from the original commit.
---@return GitObjectId?
---@return GIT_ERROR err Zero on success, GIT_EUNMERGED if there are unmerged changes in the index, GIT_EAPPLIED if the current commit has already been applied to the upstream and there is nothing to commit, -1 on failure.
function Rebase:commit(author, commiter, message)
  local new_oid = libgit2.git_oid()

  local err = libgit2.C.git_rebase_commit(
    new_oid,
    self.rebase,
    author and author.sign or nil,
    commiter.sign,
    "UTF-8",
    message
  )
  if err ~= 0 then
    return nil, err
  end

  return ObjectId.borrow(new_oid), 0
end


---Finishes a rebase that is currently in progress once all patches have been applied.
---@param signature GitSignature
---@return GIT_ERROR err Zero on success; -1 on error
function Rebase:finish(signature)
  return libgit2.C.git_rebase_finish(self.rebase, signature.sign)
end


---Gets the index produced by the last operation,
---which is the result of git_rebase_next and which will be committed
---by the next invocation of git_rebase_commit
---@return GitIndex? The result index of the last operation.
---@return GIT_ERROR
function Rebase:inmemory_index()
  local index = libgit2.git_index_double_pointer()
  local err = libgit2.C.git_rebase_inmemory_index(index, self.rebase)
  if err ~= 0 then
    return nil, err
  end

  return Index.new(index[0]), 0
end


-- ========================
-- | Repository functions |
-- ========================

---@class GitStatusItem
---@field path string File path
---@field new_path string? New file path in case of rename
---@field worktree_status GIT_DELTA Git status in worktree to index
---@field index_status GIT_DELTA Git status in index to head
---@field renamed boolean Extra flag to indicate whether item is renamed

---@class GitStatusUpstream
---@field name string
---@field oid GitObjectId?
---@field message string
---@field author string
---@field ahead integer
---@field behind integer
---@field remote string
---@field remote_url string

---@class GitStatusHead
---@field name string
---@field oid GitObjectId?
---@field message string
---@field author string
---@field is_detached boolean
---@field namespace GIT_REFERENCE_NAMESPACE
---@field refname string

---@class GitStatusResult
---@field head GitStatusHead
---@field upstream GitStatusUpstream?
---@field status GitStatusItem[]

---@class GitBranch
---@field name string
---@field shorthand string
---@field type GIT_BRANCH


---@alias GitDiffStats {changed: integer, insertions: integer, deletions: integer} Diff stats

---@alias GitDiffPatchItem {status: GIT_DELTA, path: string, new_path:string, num_hunks: integer, patch: GitPatch}


local DEFAULT_STATUS_FLAGS = bit.bor(
  libgit2.GIT_STATUS_OPT.INCLUDE_UNTRACKED,
  libgit2.GIT_STATUS_OPT.RENAMES_HEAD_TO_INDEX,
  libgit2.GIT_STATUS_OPT.RENAMES_INDEX_TO_WORKDIR,
  libgit2.GIT_STATUS_OPT.RECURSE_UNTRACKED_DIRS,
  libgit2.GIT_STATUS_OPT.SORT_CASE_SENSITIVELY
)

---Inits new Repository object
---@param git_repository ffi.cdata* libgit2.git_repository_pointer, own cdata
---@return GitRepository
function Repository.new(git_repository)
  local repo = { repo = libgit2.git_repository_pointer(git_repository) }
  setmetatable(repo, Repository)

  local c_path = libgit2.C.git_repository_path(repo.repo)
  repo.path = ffi.string(c_path)

  ffi.gc(repo.repo, libgit2.C.git_repository_free)

  return repo
end

function Repository:__tostring()
  return string.format("Git Repository: %s", self.path)
end

---Opens Git repository
---@param path string Path to repository
---@param search boolean Whether to search parent directories.
---@return GitRepository?
---@return GIT_ERROR
function Repository.open (path, search)
  local git_repo = libgit2.git_repository_double_pointer()

  local open_flag = 0
  if not search then
    open_flag = bit.bor(open_flag, libgit2.GIT_REPOSITORY_OPEN.NO_SEARCH)
  end

  local err = libgit2.C.git_repository_open_ext(git_repo, path, open_flag, nil)
  if err ~= 0 then
    return nil, err
  end

  return Repository.new(git_repo[0]), 0
end

---Checks a Repository is empty or not
---@return boolean is_empty Whether this git repo is empty
function Repository:is_empty()
  local ret = libgit2.C.git_repository_is_empty(self.repo)
  if ret == 1 then
    return true
  elseif ret == 0 then
    return false
  else
    error("Repository is corrupted, code" .. ret)
  end
end


-- Checks a Repository is bare or not
---@return boolean is_bare Whether this git repo is bare repository
function Repository:is_bare()
  local ret = libgit2.C.git_repository_is_bare(self.repo)
  return ret == 1
end


-- Checks a Repository HEAD is detached or not
---@return boolean is_head_detached Whether this git repo head detached
function Repository:is_head_detached()
  local ret = libgit2.C.git_repository_head_detached(self.repo)
  return ret == 1
end


---Get the path of this repository
function Repository:repo_path()
  return ffi.string(libgit2.C.git_repository_path(self.repo))
end


---Get the configuration file for this repository
---@return GitConfig?
---@return GIT_ERROR
function Repository:config()
  local git_config = libgit2.git_config_double_pointer()

  local err = libgit2.C.git_repository_config(git_config, self.repo)
  if err ~= 0 then
    return nil, err
  end

  return Config.new(git_config[0]), 0
end


---@param ref GitReference
---@return GitAnnotatedCommit?
---@return GIT_ERROR
function Repository:annotated_commit_from_ref(ref)
  local git_commit = libgit2.git_annotated_commit_double_pointer()

  local err = libgit2.C.git_annotated_commit_from_ref(git_commit, self.repo, ref.ref)
  if err ~= 0 then
    return nil, 0
  end

  return AnnotatedCommit.new(git_commit[0]), 0
end


---@param revspec string
---@return GitAnnotatedCommit?
---@return GIT_ERROR
function Repository:annotated_commit_from_revspec(revspec)
  local git_commit = libgit2.git_annotated_commit_double_pointer()

  local err = libgit2.C.git_annotated_commit_from_revspec(git_commit, self.repo, revspec)
  if err ~= 0 then
    return nil, 0
  end

  return AnnotatedCommit.new(git_commit[0]), 0
end


---Retrieves reference pointed at by HEAD.
---@return GitReference?
---@return GIT_ERROR
function Repository:head()
  local c_ref = libgit2.git_reference_double_pointer()
  local err = libgit2.C.git_repository_head(c_ref, self.repo)
  if err ~= 0 then
    return nil, err
  end

  return Reference.new(c_ref[0]), 0
end


---@return GitCommit?
---@return GIT_ERROR
function Repository:head_commit()
  local c_ref = libgit2.git_reference_double_pointer()
  local err = libgit2.C.git_repository_head(c_ref, self.repo)
  if err ~= 0 then
    return nil, err
  end

  local git_object = libgit2.git_object_double_pointer()
  err = libgit2.C.git_reference_peel(git_object, c_ref[0], libgit2.GIT_OBJECT.COMMIT)
  libgit2.C.git_reference_free(c_ref[0])

  if err ~= 0 then
    return nil, err
  end

  return Commit.new(ffi.cast(libgit2.git_commit_pointer, git_object[0])), 0
end

---@return GitTree?
---@return GIT_ERROR
function Repository:head_tree()
  local c_ref = libgit2.git_reference_double_pointer()
  local err = libgit2.C.git_repository_head(c_ref, self.repo)
  if err ~= 0 then
    return nil, err
  end

  local git_object = libgit2.git_object_double_pointer()
  err = libgit2.C.git_reference_peel(git_object, c_ref[0], libgit2.GIT_OBJECT.TREE)
  libgit2.C.git_reference_free(c_ref[0])

  if err ~= 0 then
    return nil, err
  end

  return Tree.new(ffi.cast(libgit2.git_tree_pointer, git_object[0])), 0
end


-- Listings branches of a repo.
---@param locals boolean Includes local branches.
---@param remotes boolean Include remote branches.
---@return GitBranch[]?
---@return GIT_ERROR
function Repository:branches(locals, remotes)
  if not locals and not remotes then
    return {}, 0
  end

  local branch_flags = 0
  if locals then
    branch_flags = libgit2.GIT_BRANCH.LOCAL
  end
  if remotes then
    branch_flags = bit.bor(branch_flags, libgit2.GIT_BRANCH.REMOTE)
  end

  local c_branch_iter = libgit2.git_branch_iterator_double_pointer()
  local err = libgit2.C.git_branch_iterator_new(c_branch_iter, self.repo, branch_flags)
  if err ~= 0 then
    return nil, err
  end

  ---@type GitBranch[]
  local branches = {}
  local c_ref = libgit2.git_reference_double_pointer()
  local c_branch_type = libgit2.unsigned_int_array(1)
  while libgit2.C.git_branch_next(c_ref, c_branch_type, c_branch_iter[0]) == 0 do
    ---@type GitBranch
    local br = {
      name = ffi.string(libgit2.C.git_reference_name(c_ref[0])),
      shorthand = ffi.string(libgit2.C.git_reference_shorthand(c_ref[0])),
      type = math.floor(tonumber(c_branch_type[0]) or 0)
    }
    table.insert(branches, br)

    libgit2.C.git_reference_free(c_ref[0])
  end

  libgit2.C.git_branch_iterator_free(c_branch_iter[0])

  return branches, 0
end


-- Calculates ahead and behind information.
---@param local_commit GitObjectId The commit which is considered the local or current state.
---@param upstream_commit GitObjectId The commit which is considered upstream.
---@return number? ahead Unique ahead commits.
---@return number? behind Unique behind commits.
---@return GIT_ERROR err Error code.
function Repository:ahead_behind(local_commit, upstream_commit)
  local c_ahead = libgit2.size_t_array(2)

  local err = libgit2.C.git_graph_ahead_behind(
    c_ahead, c_ahead + 1, self.repo, local_commit.oid, upstream_commit.oid
  )

  if err ~= 0 then
    return nil, nil, err
  end

  return tonumber(c_ahead[0]), tonumber(c_ahead[1]), 0
end


---Lookup a reference by name in a repository
---@param refname string Long name for the reference (e.g. HEAD, refs/heads/master, refs/tags/v0.1.0).
---@return GitReference?
---@return GIT_ERROR
function Repository:reference_lookup(refname)
  local ref = libgit2.git_reference_double_pointer()

  local err = libgit2.C.git_reference_lookup(ref, self.repo, refname)
  if err ~= 0 then
    return nil, 0
  end

  return Reference.new(ref[0]), 0
end


---Lookup a reference by name and resolve immediately to OID.
---@param refname string Long name for the reference (e.g. HEAD, refs/heads/master, refs/tags/v0.1.0).
---@return GitObjectId?
---@return GIT_ERROR
function Repository:reference_name_to_id(refname)
  local oid = libgit2.git_oid()
  local err = libgit2.C.git_reference_name_to_id(oid, self.repo, refname)
  if err ~= 0 then
    return nil, err
  end

  return ObjectId.borrow(oid), 0
end


-- Gets commit from a reference.
---@param oid GitObjectId
---@return GitCommit?
---@return GIT_ERROR
function Repository:commit_lookup (oid)
  local c_commit = libgit2.git_commit_double_pointer()

  local err = libgit2.C.git_commit_lookup(c_commit, self.repo, oid.oid)
  if err ~= 0 then
    return nil, err
  end

  return Commit.new(c_commit[0]), 0
end


-- Gets repository index.
---@return GitIndex?
---@return GIT_ERROR
function Repository:index ()
  local c_index = libgit2.git_index_double_pointer()

  local err = libgit2.C.git_repository_index(c_index, self.repo)
  if err ~= 0 then
    return nil, err
  end

  return Index.new(c_index[0]), 0
end


-- Updates some entries in the index from the target commit tree.
---@param paths string[]
---@return GIT_ERROR
function Repository:reset_default(paths)
  local head, ret = self:head()
  if head == nil then
    return ret
  else
    local commit, err = head:peel(libgit2.GIT_OBJECT.COMMIT)
    if commit == nil then
      return err
    elseif #paths > 0 then
      local c_paths = libgit2.const_char_pointer_array(#paths, paths)
      local strarray = libgit2.git_strarray_readonly()

      -- for i, p in ipairs(paths) do
      --   c_paths[i-1] = p
      -- end

      strarray[0].strings = c_paths
      strarray[0].count = #paths

      return libgit2.C.git_reset_default(self.repo, commit.obj, strarray);
    end
    return 0
  end
end


-- Finds the remote name of a remote-tracking branch.
---@param ref string Ref name
---@return string? remote Git remote name
---@return GIT_ERROR
function Repository:branch_remote_name(ref)
  local c_buf = libgit2.git_buf()

  local err = libgit2.C.git_branch_remote_name(c_buf, self.repo, ref)
  if err ~= 0 then
    libgit2.C.git_buf_dispose(c_buf)
    return nil, err
  end

  local remote = ffi.string(c_buf[0].ptr, c_buf[0].size)
  libgit2.C.git_buf_dispose(c_buf)

  return remote, 0
end


---Retrieves the remote of upstream of a local branch.
---@param ref string Ref name
---@return string? remote Git remote name
---@return GIT_ERROR
function Repository:branch_upstream_remote_name(ref)
  local c_buf = libgit2.git_buf()

  local err = libgit2.C.git_branch_upstream_remote(c_buf, self.repo, ref)
  if err ~= 0 then
    libgit2.C.git_buf_dispose(c_buf)
    return nil, err
  end

  local remote = ffi.string(c_buf[0].ptr, c_buf[0].size)
  libgit2.C.git_buf_dispose(c_buf)

  return remote, 0
end


---@param refname string refname
---@return string?
---@return GIT_ERROR
function Repository:branch_upstream_name(refname)
  local git_buf = libgit2.git_buf()
  local err = libgit2.C.git_branch_upstream_name(git_buf, self.repo, refname)
  if err ~= 0 then
    libgit2.C.git_buf_dispose(git_buf)
    return nil, err
  end

  local name = ffi.string(git_buf[0].ptr, git_buf[0].size)
  libgit2.C.git_buf_dispose(git_buf)

  return name, 0
end


-- Gets the information for a particular remote.
---@param remote string
---@return GitRemote?
---@return GIT_ERROR
function Repository:remote_lookup(remote)
  local c_remote = libgit2.git_remote_double_pointer()

  local err = libgit2.C.git_remote_lookup(c_remote, self.repo, remote)
  if err ~= 0 then
    return nil, err
  end

  return Remote.new(c_remote[0]), 0
end

---Gets a list of the configured remotes for a repo
---@return string[]?
---@return GIT_ERROR
function Repository:remote_list()
  local strarr = libgit2.git_strarray()

  local err = libgit2.C.git_remote_list(strarr, self.repo)
  if err ~= 0 then
    return nil, err
  end

  local remotes = {} --[[@as string[] ]]
  local num_remotes = tonumber(strarr[0].count) or 0
  for i = 0,num_remotes-1 do
    remotes[i+1] = ffi.string(strarr[0].strings[i])
  end
  libgit2.C.git_strarray_dispose(strarr)

  return remotes, 0
end


---Reads status of a given file path.
---this can't detect a rename.
---@param path string Git file path.
---@return GIT_DELTA worktree_status Git Status in worktree.
---@return GIT_DELTA index_status Git Status in index.
---@return GIT_ERROR return_code Git return code.
function Repository:status_file(path)
  local worktree_status, index_status = libgit2.GIT_DELTA.UNMODIFIED, libgit2.GIT_DELTA.UNMODIFIED
  local c_status = libgit2.unsigned_int_array(1)

  local err = libgit2.C.git_status_file(c_status, self.repo, path)
  if err ~= 0 then
    return worktree_status, index_status, err
  end

  local status = tonumber(c_status[0])
  if status ~= nil then
    if bit.band(status, libgit2.GIT_STATUS.WT_NEW) ~= 0 then
      worktree_status = libgit2.GIT_DELTA.UNTRACKED
      index_status = libgit2.GIT_DELTA.UNTRACKED
    elseif bit.band(status, libgit2.GIT_STATUS.WT_MODIFIED) ~= 0 then
      worktree_status = libgit2.GIT_DELTA.MODIFIED
    elseif bit.band(status, libgit2.GIT_STATUS.WT_DELETED) ~= 0 then
      worktree_status = libgit2.GIT_DELTA.DELETED
    elseif bit.band(status, libgit2.GIT_STATUS.WT_TYPECHANGE) ~= 0 then
      worktree_status = libgit2.GIT_DELTA.TYPECHANGE
    elseif bit.band(status, libgit2.GIT_STATUS.WT_UNREADABLE) ~= 0 then
      worktree_status = libgit2.GIT_DELTA.UNREADABLE
    elseif bit.band(status, libgit2.GIT_STATUS.IGNORED) ~= 0 then
      worktree_status = libgit2.GIT_DELTA.IGNORED
    elseif bit.band(status, libgit2.GIT_STATUS.CONFLICTED) ~= 0 then
      worktree_status = libgit2.GIT_DELTA.CONFLICTED
    end

    if bit.band(status, libgit2.GIT_STATUS.INDEX_NEW) ~= 0 then
      index_status = libgit2.GIT_DELTA.ADDED
    elseif bit.band(status, libgit2.GIT_STATUS.INDEX_MODIFIED) ~= 0 then
      index_status = libgit2.GIT_DELTA.MODIFIED
    elseif bit.band(status, libgit2.GIT_STATUS.INDEX_DELETED) ~= 0 then
      index_status = libgit2.GIT_DELTA.DELETED
    elseif bit.band(status, libgit2.GIT_STATUS.INDEX_TYPECHANGE) ~= 0 then
      index_status = libgit2.GIT_DELTA.TYPECHANGE
    end
  end

  return worktree_status, index_status, 0
end


-- Reads the status of the repository and returns a dictionary.
-- with file paths as keys and status flags as values.
---@return GitStatusResult? status_result git status result.
---@return integer return_code Return code.
function Repository:status()
  ---@type GIT_ERROR
  local err

  local opts = libgit2.git_status_options(libgit2.GIT_STATUS_OPTIONS_INIT)
  -- libgit2.C.git_status_options_init(opts, libgit2.GIT_STATUS_OPTIONS_VERSION)
  opts[0].show = libgit2.GIT_STATUS_SHOW.INDEX_AND_WORKDIR
  opts[0].flags = DEFAULT_STATUS_FLAGS

  local status = libgit2.git_status_list_double_pointer()
  err = libgit2.C.git_status_list_new(status, self.repo, opts)
  if err ~= 0 then
    return nil, err
  end

  -- Get Head information
  local repo_head
  repo_head, err = self:head()
  if repo_head == nil then
    return nil, err
  end

  -- local repo_head_oid, _ = repo_head:target()
  -- if repo_head_oid ~= nil then
  --   repo_head_oid_str = tostring(repo_head_oid)
  --   repo_head_msg = self:commit_lookup(repo_head_oid):message()
  -- end

  local repo_head_commit, _ = repo_head:peel_commit()
  local repo_head_oid = repo_head_commit and repo_head_commit:id() or nil

  ---@type GitStatusResult
  local result = {
    head = {
      name        = repo_head:shorthand(),
      oid         = repo_head_oid,
      author      = repo_head_commit and repo_head_commit:author() or "",
      message     = repo_head_commit and repo_head_commit:message() or "",
      is_detached = self:is_head_detached(),
      namespace   = repo_head.namespace,
      refname     = repo_head.name,
    },
    status = {}
  }

  -- Get upstream information
  local repo_upstream
  repo_upstream, err = repo_head:branch_upstream()
  if repo_upstream then
    ---@type number
    local ahead, behind = 0, 0
    local commit_local = repo_head_oid
    -- local commit_upstream, _ = repo_upstream:target()
    local commit_upstream, _ = repo_upstream:peel_commit()
    local commit_upstream_oid = commit_upstream and commit_upstream:id() or nil

    if commit_upstream_oid and commit_local then
      local nilable_ahead, nilable_behind, _ = self:ahead_behind(commit_local, commit_upstream_oid)
      if nilable_ahead ~= nil and nilable_behind ~= nil then
        ahead, behind = nilable_ahead, nilable_behind
      end
    end

    local remote
    local remote_name = repo_upstream:remote_name()
    if remote_name then
      remote, _ = self:remote_lookup(remote_name)
    end

    result.upstream = {
      name       = repo_upstream:shorthand(),
      oid        = commit_upstream_oid,
      message    = commit_upstream and commit_upstream:message() or "",
      author     = commit_upstream and commit_upstream:author() or "",
      ahead      = ahead,
      behind     = behind,
      remote     = remote and remote.name or "",
      remote_url = remote and remote.url or "",
    }
  end

  local n_entry = tonumber(libgit2.C.git_status_list_entrycount(status[0]))

  -- Iterate through git status list
  for i = 0,n_entry-1 do
    local entry = libgit2.C.git_status_byindex(status[0], i)
    if entry == nil or entry.status == libgit2.GIT_STATUS.CURRENT then
      goto git_status_list_continue
    end

    ---@type GitStatusItem
    local status_item = {
      path            = "",
      worktree_status = libgit2.GIT_DELTA.UNMODIFIED,
      index_status    = libgit2.GIT_DELTA.UNMODIFIED,
      renamed         = false,
    }
    ---@type string
    local old_path, new_path

    if entry.index_to_workdir ~= nil then
      old_path = ffi.string(entry.index_to_workdir.old_file.path)
      new_path = ffi.string(entry.index_to_workdir.new_file.path)

      status_item.path = old_path
      status_item.worktree_status = entry.index_to_workdir.status

      if bit.band(entry.status, libgit2.GIT_STATUS.WT_NEW) ~= 0 then
        status_item.worktree_status = libgit2.GIT_DELTA.UNTRACKED
        status_item.index_status = libgit2.GIT_DELTA.UNTRACKED
      end

      if bit.band(entry.status, libgit2.GIT_STATUS.WT_RENAMED) ~= 0 then
        status_item.renamed = true
        status_item.new_path = new_path
      end
    end

    if entry.head_to_index ~= nil then
      old_path = ffi.string(entry.head_to_index.old_file.path)
      new_path = ffi.string(entry.head_to_index.new_file.path)

      status_item.path = old_path
      status_item.index_status = entry.head_to_index.status

      if bit.band(entry.status, libgit2.GIT_STATUS.INDEX_RENAMED) ~= 0 then
        status_item.renamed = true
        status_item.new_path = new_path
      end
    end

    table.insert(result.status, status_item)
    ::git_status_list_continue::
  end

  -- free C resources
  libgit2.C.git_status_list_free(status[0])

  return result, 0
end


---Get default remote
---@return GitRemote?
---@return GIT_ERROR
function Repository:remote_default()
  local remote, remotes, err

  remote, err = self:remote_lookup("origin")
  if err ~= 0 then
    remotes, err = self:remote_list()
    if err ~= 0 then
      return nil, 0
    end

    if remotes and #remotes > 0 then
      -- get other remote as default if origin is not found
      remote, err = self:remote_lookup(remotes[1])
    else
      return nil, 0
    end
  end
  return remote, err
end


---Retrieve pushremote for a branch, if not found
---returns remote from config.
---@param name string branch name
---@return string?
function Repository:branch_push_remote(name)
  if name == "" then
    return nil
  end

  local config, _ = self:config()
  if not config then
    return nil
  end

  local config_prefix = "branch." .. name
  return config:get_string(config_prefix .. ".pushremote")
    or config:get_string(config_prefix .. ".remote")
end


---Default signature user and now timestamp.
---@return GitSignature?
---@return GIT_ERROR
function Repository:signature_default()
  local git_signature = libgit2.git_signature_double_pointer()

  local err = libgit2.C.git_signature_default(git_signature, self.repo);
  if err ~= 0 then
    return nil, err
  end

  return Signature.new(git_signature[0]), 0
end


---Creates new commit in the repository.
---@param index GitIndex
---@param signature GitSignature
---@param message string
---@return GitObjectId?
---@return GIT_ERROR
function Repository:commit(index, signature, message)
  -- get head as parent commit
  local head, err = self:head()
  if err ~= 0 and err ~= libgit2.GIT_ERROR.GIT_ENOTFOUND then
    return nil, err
  end
  local parent = nil
  if head then
    parent, err = head:peel_commit()
    if err ~= 0 then
      return nil, err
    end
  end

  local tree_id
  tree_id, err = index:write_tree()
  if not tree_id then
    return nil, err
  end

  local tree = libgit2.git_tree_double_pointer()
  err = libgit2.C.git_tree_lookup(tree, self.repo, tree_id.oid)
  if err ~= 0 then
    return nil, err
  end

  local git_oid = libgit2.git_oid()
  err = libgit2.C.git_commit_create_v(
    git_oid,
    self.repo, "HEAD",
    signature.sign[0], signature.sign[0],
    "UTF-8", message,
    tree[0],
    parent and 1 or 0,
    parent and parent.commit or nil
  )
  libgit2.C.git_tree_free(tree[0])
  if err ~= 0 then
    return nil, err
  end

  return ObjectId.borrow(git_oid), 0
end

---Lookup a blob object from a repository.
---@param id GitObjectId
---@return GitBlob?
---@return GIT_ERROR
function Repository:blob_lookup(id)
  local blob = libgit2.git_blob_double_pointer()
  local err =  libgit2.C.git_blob_lookup(blob, self.repo, id.oid)
  if err ~= 0 then
    return nil, err
  end
  return Blob.new(blob[0]), 0
end


---Rewords HEAD commit.
---@param signature GitSignature
---@param message string
---@return GitObjectId?
---@return GIT_ERROR
function Repository:amend_reword(signature, message)
  return self:amend(nil, signature, message)
end


---Extends new index to HEAD commit.
---@param index GitIndex
---@return GitObjectId?
---@return GIT_ERROR
function Repository:amend_extend(index)
  return self:amend(index, nil, nil)
end

---Amends an existing commit by replacing only non-NULL values.
---@param index GitIndex?
---@param signature GitSignature?
---@param message string?
---@return GitObjectId?
---@return GIT_ERROR
function Repository:amend(index, signature, message)
  -- get head as parent commit
  local head, head_commit, err
  head, err = self:head()
  if not head then
    return nil, err
  end
  head_commit, err = head:peel_commit()
  if not head_commit then
    return nil, err
  end

  if not (index or signature or message) then
    return head_commit:id(), 0
  end

  local tree = nil
  if index then
    local tree_id
    tree_id, err = index:write_tree()
    if not tree_id then
      return nil, err
    end

    tree = libgit2.git_tree_double_pointer()
    err = libgit2.C.git_tree_lookup(tree, self.repo, tree_id.oid)
    if err ~= 0 then
      return nil, err
    end
  end

  local sig = signature and signature.sign or nil

  local git_oid = libgit2.git_oid()
  err = libgit2.C.git_commit_amend(
    git_oid,
    head_commit.commit,
    "HEAD",
    sig, sig, nil, message,
    tree ~= nil and tree[0] or nil
  )

  if tree ~= nil then
    libgit2.C.git_tree_free(tree[0])
  end

  if err ~= 0 then
    return nil, err
  end

  return ObjectId.borrow(git_oid), 0
end


---Returns a GitRevisionWalker, cached it for the repo if possible.
---@return GitRevisionWalker?
---@return GIT_ERROR
function Repository:walker()
  if self._walker then
    return self._walker, 0
  end

  local walker = libgit2.git_revwalk_double_pointer()
  local err = libgit2.C.git_revwalk_new(walker, self.repo)
  if err ~= 0 then
    return nil, err
  end

  self._walker = RevisionWalker.new(self.repo, walker[0])
  return self._walker, 0
end


---Frees a cached GitRevisionWalker
function Repository:free_walker()
  if self._walker then
    self._walker = nil
  end
end


---Helper function to keep consistency between
---git_status_options and git_diff_options
---@param status_flag GIT_STATUS_OPT
---@return GIT_DIFF diff_flag
---@return GIT_DIFF_FIND find_flag
local function git_status_flags_to_diff_flags(status_flag)
  local diff_flag = libgit2.GIT_DIFF.INCLUDE_TYPECHANGE
  local find_flag = libgit2.GIT_DIFF_FIND.FIND_FOR_UNTRACKED

  if bit.band(status_flag, libgit2.GIT_STATUS_OPT.INCLUDE_UNTRACKED) ~= 0 then
    diff_flag = bit.bor(diff_flag, libgit2.GIT_DIFF.INCLUDE_UNTRACKED)
  end
  if bit.band(status_flag, libgit2.GIT_STATUS_OPT.INCLUDE_IGNORED) ~= 0 then
		diff_flag = bit.bor(diff_flag, libgit2.GIT_DIFF.INCLUDE_IGNORED)
  end
	if bit.band(status_flag, libgit2.GIT_STATUS_OPT.INCLUDE_UNMODIFIED) ~= 0 then
		diff_flag = bit.bor(diff_flag, libgit2.GIT_DIFF.INCLUDE_UNMODIFIED)
  end
	if bit.band(status_flag, libgit2.GIT_STATUS_OPT.RECURSE_UNTRACKED_DIRS) ~= 0 then
		diff_flag = bit.bor(diff_flag,
      libgit2.GIT_DIFF.RECURSE_UNTRACKED_DIRS,
      libgit2.GIT_DIFF.SHOW_UNTRACKED_CONTENT
    )
  end
	if bit.band(status_flag, libgit2.GIT_STATUS_OPT.DISABLE_PATHSPEC_MATCH) ~= 0 then
		diff_flag = bit.bor(diff_flag, libgit2.GIT_DIFF.DISABLE_PATHSPEC_MATCH)
  end
	if bit.band(status_flag, libgit2.GIT_STATUS_OPT.RECURSE_IGNORED_DIRS) ~= 0 then
		diff_flag = bit.bor(diff_flag, libgit2.GIT_DIFF.RECURSE_IGNORED_DIRS)
  end
	if bit.band(status_flag, libgit2.GIT_STATUS_OPT.EXCLUDE_SUBMODULES) ~= 0 then
		diff_flag = bit.bor(diff_flag, libgit2.GIT_DIFF.IGNORE_SUBMODULES)
  end
	if bit.band(status_flag, libgit2.GIT_STATUS_OPT.UPDATE_INDEX) ~= 0 then
		diff_flag = bit.bor(diff_flag, libgit2.GIT_DIFF.UPDATE_INDEX)
  end
	if bit.band(status_flag, libgit2.GIT_STATUS_OPT.INCLUDE_UNREADABLE) ~= 0 then
		diff_flag = bit.bor(diff_flag, libgit2.GIT_DIFF.INCLUDE_UNREADABLE)
  end
	if bit.band(status_flag, libgit2.GIT_STATUS_OPT.INCLUDE_UNREADABLE_AS_UNTRACKED) ~= 0 then
		diff_flag = bit.bor(diff_flag, libgit2.GIT_DIFF.INCLUDE_UNREADABLE_AS_UNTRACKED)
  end

	if bit.band(status_flag, libgit2.GIT_STATUS_OPT.RENAMES_FROM_REWRITES) ~= 0 then
		find_flag = bit.bor(
      find_flag,
      libgit2.GIT_DIFF_FIND.FIND_AND_BREAK_REWRITES,
      libgit2.GIT_DIFF_FIND.FIND_RENAMES_FROM_REWRITES,
      libgit2.GIT_DIFF_FIND.BREAK_REWRITES_FOR_RENAMES_ONLY
    )
  end

  return diff_flag, find_flag
end


---@param index GitIndex? Repository index, can be null
---@param paths string[]? Git paths, can be null
---@param reverse? boolean whether to reverse the diff
---@return GitDiff?
---@return GIT_ERROR
function Repository:diff_index_to_workdir(index, paths, reverse)
  return self:diff_helper(true, true, index, paths, reverse)
end

---@param index GitIndex? Repository index, can be null
---@param paths string[]? Git paths, can be null
---@param reverse? boolean whether to reverse the diff
---@return GitDiff?
---@return GIT_ERROR
function Repository:diff_head_to_index(index, paths, reverse)
  return self:diff_helper(false, true, index, paths, reverse)
end


---@param index GitIndex? Repository index, can be null
---@param paths string[]? Git paths, can be null
---@param reverse? boolean whether to reverse the diff
---@return GitDiff?
---@return GIT_ERROR
function Repository:diff_head_to_workdir(index, paths, reverse)
  return self:diff_helper(true, false, index, paths, reverse)
end

---@param include_workdir boolean Whether to do include workd_dir in diff target
---@param include_index boolean Wheter to include index in diff target
---@param index GitIndex? Repository index, can be null
---@param paths string[]? Git paths, can be null
---@param reverse boolean? Reverse diff
---@return GitDiff?
---@return GIT_ERROR
function Repository:diff_helper(include_workdir, include_index, index, paths, reverse)
  local c_paths, err
  local opts = libgit2.git_diff_options(libgit2.GIT_DIFF_OPTIONS_INIT)
  local find_opts = libgit2.git_diff_find_options(libgit2.GIT_DIFF_FIND_OPTIONS_INIT)
  local diff = libgit2.git_diff_double_pointer()

  opts[0].id_abbrev = 8
  opts[0].flags, find_opts[0].flags = git_status_flags_to_diff_flags(DEFAULT_STATUS_FLAGS)

  if reverse then
    opts[0].flags = bit.bor(opts[0].flags, libgit2.GIT_DIFF.REVERSE)
  end

  if paths and #paths > 0 then
    c_paths = libgit2.const_char_pointer_array(#paths, paths)
    opts[0].pathspec.strings = c_paths
    opts[0].pathspec.count = #paths
  end

  if include_workdir and include_index then
    -- diff workdir to index
    err = libgit2.C.git_diff_index_to_workdir(
      diff, self.repo, index and index.index or nil, opts
    )
  elseif include_workdir or include_index then
    -- diff workd_dir to head or index to head

    local head, head_tree
    head, err = self:head()
    -- if there is no HEAD, that's okay - we'll make an empty iterator
    if err ~= 0 and err ~= libgit2.GIT_ERROR.GIT_ENOTFOUND and err ~= libgit2.GIT_ERROR.GIT_EUNBORNBRANCH then
      return nil, err
    end
    if head then
      head_tree, err = head:peel(libgit2.GIT_OBJECT.TREE)
      if err ~= 0 then
        return nil, err
      end
    end

    if include_index then
      -- diff index to head
      err = libgit2.C.git_diff_tree_to_index(
        diff, self.repo,
        head_tree and ffi.cast(libgit2.git_tree_pointer, head_tree.obj) or nil,
        index and index.index or nil, opts
      )
    else
      -- diff workd_dir to head
      err = libgit2.C.git_diff_tree_to_workdir(
        diff, self.repo,
        head_tree and ffi.cast(libgit2.git_tree_pointer, head_tree.obj) or nil,
        opts
      )
    end
  else
    return nil, 0
  end

  if err ~= 0 then
    return nil, err
  end

  -- call this to detect rename
  if include_workdir and bit.band(DEFAULT_STATUS_FLAGS, libgit2.GIT_STATUS.WT_RENAMED) ~= 0
    or (include_index and bit.band(DEFAULT_STATUS_FLAGS, libgit2.GIT_STATUS.INDEX_RENAMED) ~= 0)
  then
    err = libgit2.C.git_diff_find_similar(diff[0], find_opts)
    if err ~= 0 then
      libgit2.C.git_diff_free(diff[0])
      return nil, err
    end
  end

  return Diff.new(diff[0]), 0
end

---Applies a diff into workdir
---@param diff GitDiff
---@return GIT_ERROR
function Repository:apply_workdir(diff)
  return self:apply(diff, true, false)
end

---Applies a diff into index
---@param diff GitDiff
---@return GIT_ERROR
function Repository:apply_index(diff)
  return self:apply(diff, false, true)
end

---Applies a diff into index and workdir
---@param diff GitDiff
---@return GIT_ERROR
function Repository:apply_workdir_index(diff)
  return self:apply(diff, true, true)
end

---Applies a diff into workdir or index
---@param diff GitDiff
---@param workdir boolean Apply to workdir
---@param index boolean Apply to index
---@return GIT_ERROR
function Repository:apply(diff, workdir, index)
  if not (workdir or index) then
    return 0
  end

  local opts = libgit2.git_apply_options(libgit2.GIT_APPLY_OPTIONS_INIT)
  local location = 0
  if workdir then
    location = bit.bor(location, libgit2.GIT_APPLY_LOCATION.WORKDIR)
  end
  if index then
    location = bit.bor(location, libgit2.GIT_APPLY_LOCATION.INDEX)
  end

  return libgit2.C.git_apply(self.repo, diff.diff, location, opts)
end


---@param oid GitObjectId
---@return GitTag?
---@return GIT_ERROR
function Repository:tag_lookup(oid)
  local git_tag = libgit2.git_tag_double_pointer()

  local err = libgit2.C.git_tag_lookup(git_tag, self.repo, oid.oid)
  if err ~= 0 then
    return nil, err
  end

  return Tag.new(git_tag[0]), 0
end


---Lookup a branch by its name in a repository.
---@param branch_name string branch name
---@param branch_type GIT_BRANCH
---@return GitReference?
---@return GIT_ERROR
function Repository:branch_lookup(branch_name, branch_type)
  local ref = libgit2.git_reference_double_pointer()

  local err = libgit2.C.git_branch_lookup(ref, self.repo, branch_name, branch_type)
  if err ~= 0 then
    return nil, err
  end

  return Reference.new(ref[0]), 0
end


---@param remote_name string remote name
---@return string?
---@return GIT_ERROR
function Repository:remote_default_branch(remote_name)
  local remote_head = string.format("refs/remotes/%s/HEAD", remote_name)
  local ref, err = self:reference_lookup(remote_head)
  if not ref then
    return nil, err
  end

  local target = ref:symbolic_target()
  if not target then
    return nil, err
  end

  return target, 0
end


---Initializes a rebase operation
---@param branch GitAnnotatedCommit?
---@param upstream GitAnnotatedCommit?
---@param onto GitAnnotatedCommit?
---@param opts { inmemory: boolean? }
---@return GitRebase?
---@return GIT_ERROR
function Repository:rebase_init(branch, upstream, onto, opts)
  local git_rebase = libgit2.git_rebase_double_pointer()
  local rebase_opts = libgit2.git_rebase_options(libgit2.GIT_REBASE_OPTIONS_INIT)

  if opts.inmemory then
    rebase_opts[0].inmemory = 1
  end

  local err = libgit2.C.git_rebase_init(
    git_rebase,
    self.repo,
    branch and branch.commit,
    upstream and upstream.commit,
    onto and onto.commit,
    rebase_opts
  )
  if err ~= 0 then
    return nil, 0
  end

  return Rebase.new(git_rebase[0]), 0
end


---Opens an existing rebase.
---@return GitRebase?
---@return GIT_ERROR
function Repository:rebase_open()
  local git_rebase = libgit2.git_rebase_double_pointer()
  local opts = libgit2.git_rebase_options(libgit2.GIT_REBASE_OPTIONS_INIT)

  local err = libgit2.C.git_rebase_open(
    git_rebase, self.repo, opts
  )
  if err ~= 0 then
    return nil, 0
  end

  return Rebase.new(git_rebase[0]), 0
end


-- ===================
-- | Utils functions |
-- ===================


---Set a library global option
---@param option GIT_OPT
---@param value integer
---@return integer success code
local function libgit2_set_opts(option, value)
  local ret = libgit2.C.git_libgit2_opts(option, value)
  return ret
end


---@param delta GIT_DELTA
---@return string char Git status char such as M, A, D.
local function status_char(delta)
  local c = libgit2.C.git_diff_status_char(delta);
  return string.char(c)
end


---Same as status_char but replace " " by "-"
---@param delta GIT_DELTA
---@return string Git status char such as M, A, D.
local function status_char_dash(delta)
  local c = libgit2.C.git_diff_status_char(delta);
  if c == 32 then
    return "-"
  end
  return string.char(c)
end


---@param delta GIT_DELTA
---@return string status status full string such as "UNTRACKED"
local function status_string(delta)
  return GIT_DELTA_STRING[delta+1]
end


---Prettifiy git message
---@param msg string
local function message_prettify(msg)
  local c_buf = libgit2.git_buf()

  local err = libgit2.C.git_buf_grow(c_buf, msg:len() + 1)
  if err ~= 0 then
    return nil, err
  end

  err = libgit2.C.git_message_prettify(c_buf, msg, 1, string.byte("#"))
  if err ~= 0 then
    libgit2.C.git_buf_dispose(c_buf)
    return nil, err
  end

  local prettified = ffi.string(c_buf[0].ptr, c_buf[0].size)
  libgit2.C.git_buf_dispose(c_buf)

  return prettified, 0
end


-- ==================
-- | Git2Module     |
-- ==================

---@class Git2Module
local M = {}

M.Config = Config
M.Diff = Diff
M.Repository = Repository
M.Reference = Reference


M.GIT_ERROR = libgit2.GIT_ERROR
M.GIT_BRANCH = libgit2.GIT_BRANCH
M.GIT_DELTA = libgit2.GIT_DELTA
M.GIT_REFERENCE = libgit2.GIT_REFERENCE
M.GIT_REFERENCE_NAMESPACE = GIT_REFERENCE_NAMESPACE
M.GIT_INDEX_STAGE = libgit2.GIT_INDEX_STAGE
M.GIT_OPT = libgit2.GIT_OPT
M.GIT_OBJECT = libgit2.GIT_OBJECT
M.GIT_REBASE_NO_OPERATION = libgit2.GIT_REBASE_NO_OPERATION
M.GIT_REBASE_OPERATION = libgit2.GIT_REBASE_OPERATION


M.head = Repository.head
M.status = Repository.status
M.set_opts = libgit2_set_opts
M.status_char = status_char
M.status_char_dash = status_char_dash
M.status_string = status_string
M.message_prettify = message_prettify
M.reference_name_namespace = reference_name_namespace
M.reference_name_shorthand = reference_name_shorthand
M.reference_name_remote = reference_name_remote


function M.destroy()
  libgit2_init_count = libgit2.C.git_libgit2_shutdown()
end


return M
