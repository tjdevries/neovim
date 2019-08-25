#ifndef NVIM_EX_DOCMD_H
#define NVIM_EX_DOCMD_H

#include "nvim/ex_cmds_defs.h"
#include "nvim/globals.h"

// flags for do_cmdline()
#define DOCMD_VERBOSE   0x01      // included command in error message
#define DOCMD_NOWAIT    0x02      // don't call wait_return() and friends
#define DOCMD_REPEAT    0x04      // repeat exec. until getline() returns NULL
#define DOCMD_KEYTYPED  0x08      // don't reset KeyTyped
#define DOCMD_EXCRESET  0x10      // reset exception environment (for debugging
#define DOCMD_KEEPLINE  0x20      // keep typed line for repeating with "."

/* defines for eval_vars() */
#define VALID_PATH              1
#define VALID_HEAD              2

/* Values for exmode_active (0 is no exmode) */
#define EXMODE_NORMAL           1
#define EXMODE_VIM              2

// Structure used to save the current state.  Used when executing Normal mode
// commands while in any other mode.
typedef struct {
  int save_msg_scroll;
  int save_restart_edit;
  int save_msg_didout;
  int save_State;
  int save_insertmode;
  bool save_finish_op;
  long save_opcount;
  int save_reg_executing;
  tasave_T tabuf;
} save_state_T;

typedef enum getline_type_T {
  GETLINE_FUNC,
  GETLINE_EX,
  GETLINE_EX_MODE,
  GETLINE_SOURCE,
  GETLINE_OTHER
} getline_type_T;

/// Struct to save a few things while debugging.  Used in do_cmdline() only.
struct CmdlineDebugState {
  int trylevel;
  int force_abort;
  except_T    *caught_stack;
  char_u      *vv_exception;
  char_u      *vv_throwpoint;
  int did_emsg;
  int got_int;
  int need_rethrow;
  int check_cstack;
  except_T    *current_exception;
};

typedef struct CmdlineContext {
  int initial_trylevel;
  struct CmdlineDebugState initial_debug_stuff;

  struct msglist **initial_msg_list;
  struct msglist *private_msg_list;

  char_u *cmdline;
  LineGetter fgetline;
  getline_type_T line_type;

  int flags;
  int *ptr_call_depth;
  int *ptr_recursive;

  void *cookie;
  void *real_cookie;

  cstack_T *cstack;
} CmdlineContext_T;

typedef struct CmdlineLoopResult {
  int initial_msg_didout;
  int did_inc;
  int retval;
} CmdlineLoopResult_T;

typedef struct CmdlineTeardown {
  int retval;
  int call_depth;
} CmdlineTeardown_T;



#ifdef INCLUDE_GENERATED_DECLARATIONS
# include "ex_docmd.h.generated.h"
#endif

#endif  // NVIM_EX_DOCMD_H
