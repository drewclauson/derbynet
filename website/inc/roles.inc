<?php
// DO NOT EDIT THIS FILE!!
//

require_once('inc/permissions.inc');

// Define your roles and permissions, and assign passwords, in
// local/config-roles.inc.

// Upon first connection, a role without a password, if any, will be
// selected from the $roles array, and the contained permissions
// assigned.  There should only be one such role, and the permissions
// associated with that role are what a non-logged-in user can do.
$configdir = isset($_SERVER['CONFIG_DIR']) ? $_SERVER['CONFIG_DIR'] : 'local';
@include_once($configdir.DIRECTORY_SEPARATOR.'config-roles.inc');

if (!isset($roles)) {
  // If local/config-roles.inc doesn't exist, or for some other reason
  // doesn't set up the $roles array, then fall back to this value,
  // which grants unlimited power to the anonymous user.  That's
  // definitely NOT what we want after initial set-up is done.
  $roles = array('' => 
                 array('password' => '',
                       'permissions' => -1)
    );
}


?>