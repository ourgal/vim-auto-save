if !has('vim9script') ||  v:version < 900
    finish
endif
vim9script
#======================================
#    Script Name:  vim-auto-save (http://www.vim.org/scripts/script.php?script_id=4521)
#    Plugin Name:  AutoSave
#        Version:  0.1.13
#======================================

if exists("g:auto_save_loaded")
  finish
else
  g:auto_save_loaded = true
endif

const save_cpo = &cpo
set cpo&vim

if !exists("g:auto_save")
  g:auto_save = false
endif

if !exists("g:auto_save_silent")
  g:auto_save_silent = false
endif

if !exists("g:auto_save_write_all_buffers")
  g:auto_save_write_all_buffers = false
endif

if !exists("g:auto_save_events")
  g:auto_save_events = ["InsertLeave", "TextChanged"]
endif

def FilterEvents(_: number, event: string): bool
  if !exists("##" .. event)
    echo "(AutoSave) Save on " .. event .. " event is not supported for your Vim version!"
    echo "(AutoSave) " .. event .. " was removed from g:auto_save_events variable."
    echo "(AutoSave) Please, upgrade your Vim to a newer version or use other events in g:auto_save_events!"

    return false
  endif

  return true
enddef

# Check all used events exist
g:auto_save_events->filter(FilterEvents)

augroup auto_save
  autocmd!
  execute "au" g:auto_save_events->join(',') "* ++nested AutoSave()"
augroup END

command AutoSaveToggle AutoSaveToggle()

def AutoSave()
  if !GetVar('auto_save')
    return
  endif

  const was_modified = IsModified()
  if !was_modified
    return
  endif

  if exists("g:auto_save_presave_hook")
    g:auto_save_abort = 0
    execute g:auto_save_presave_hook
    if g:auto_save_abort >= 1
      return
    endif
  endif

  # Preserve marks that are used to remember start and
  # end position of the last changed or yanked text (`:h '[`).
  const first_char_pos = getpos("'[")
  const last_char_pos = getpos("']")

  # Preserve the window view.
  const window_view = winsaveview()

  DoSave()

  winrestview(window_view)

  setpos("'[", first_char_pos)
  setpos("']", last_char_pos)

  if was_modified && !&modified
    if exists("g:auto_save_postsave_hook")
      execute g:auto_save_postsave_hook
    endif

    if !g:auto_save_silent
      echo "(AutoSave) saved at " .. strftime("%H:%M:%S")
    endif
  endif
enddef

def IsModified(): bool
  if g:auto_save_write_all_buffers
    const buffers = 1->range(bufnr('$'))->filter((_, v) => bufexists(v))->filter((_, v) => v->getbufvar('&modified'))
    return len(buffers) > 0
  else
    return &modified
  endif
enddef

# Resolve variable value by climbing up window-buffer-global hierarchy
# So, buffer-local or window-local variables override global ones
# If not found on any level, fallbacks to default value or empty string
def GetVar(varName: string, default: bool = false): bool
  if exists('w:' .. varName)
    return get(w:, varName)
  elseif exists('b:' .. varName)
    return get(b:, varName)
  elseif exists('g:' .. varName)
    return get(g:, varName)
  else
    return default
  endif
enddef

def DoSave(): void
  if g:auto_save_write_all_buffers
    const current_buf = bufnr('%')
    silent! bufdo update
    execute 'buffer' current_buf
  else
    silent! update
  endif
enddef

def AutoSaveToggle()
  if g:auto_save
    echo "(AutoSave) OFF"
  else
    echo "(AutoSave) ON"
  endif
  g:auto_save = !g:auto_save
enddef

&cpo = save_cpo
