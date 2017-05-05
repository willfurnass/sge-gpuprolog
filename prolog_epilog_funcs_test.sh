#!/bin/bash

source prolog_epilog_funcs.sh

function can_assert_that_string_is_empty() {
  assertion__string_empty ""
}

function can_get_gpu_req_per_slot {
    mock__make_function_prints "qstat" "$(cat qstat.test)"
    assertion__equal "$(get_gpu_req_per_slot 12345)" 1
#}

