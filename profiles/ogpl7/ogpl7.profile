<?php


/*
 * Implements hook_install_tasks_alter()
 */
function ogpl7_install_tasks_alter(&$tasks, $install_state) {

  // substitute our own finished step
  $tasks['install_finished'] = array(
    'display_name' => st('Installation has been finished successfully'),
    'display' => 1,
    'function' => 'ogpl7_install_finished',
  );
    
}

function ogpl7_install_finished(&$install_state) {
  drupal_set_title(st('@drupal installation complete', array('@drupal' => drupal_install_profile_distribution_name())), PASS_THROUGH);
  $messages = drupal_set_message();
  $output = '<p>' . st('Congratulations, you installed @drupal!', array('@drupal' => drupal_install_profile_distribution_name())) . '</p>';
  $output .= '<p>' . (isset($messages['error']) ? st('Review the messages above before enabling <a href="@url">the features of your new site</a>.', array('@url' => url('admin/structure/features'))) : st('<a href="@url">Visit your new site and enable features</a>.', array('@url' => url('admin/structure/features')))) . '</p>';   

  // Flush all caches to ensure that any full bootstraps during the installer
  // do not leave stale cached data, and that any content types or other items
  // registered by the install profile are registered correctly.
  drupal_flush_all_caches();

  // Remember the profile which was used.
  variable_set('install_profile', drupal_get_profile());

  // Install profiles are always loaded last
  db_update('system')
    ->fields(array('weight' => 1000))
    ->condition('type', 'module')
    ->condition('name', drupal_get_profile())
    ->execute();

  // Cache a fully-built schema.
  drupal_get_schema(NULL, TRUE);

  // Run cron to populate update status tables (if available) so that users
  // will be warned if they've installed an out of date Drupal version.
  // Will also trigger indexing of profile-supplied content or feeds.
  drupal_cron_run();
  
  // fix Demo Community menu link parent 
  $item = array(
    'menu_name' => 'main-menu',
    'module' => 'system',
    'link_path' => 'communities',
    'router_path' => 'communities',
    'link_title' => 'Communities',
  );
  $plid = menu_link_save($item);


  // get mlid of "Demo Community" menu link
    $result = db_select('menu_links', 'm')
    ->fields('m')
    ->condition('link_title', 'Demo-Community','=')
    ->condition('link_path', 'node/1','=')
    ->condition('module', 'menu','=')
    ->execute()
    ->fetchAssoc();
  $mlid = $result['mlid'];

  // set plid of "Demo Community" menu link
  $item = array(
    'plid' => $plid,
    'mlid' => $mlid,
    'menu_name' => 'main-menu',
    'module' => 'menu',
    'link_path' => 'node/1',
    'link_title' => 'Demo Community',
  );
  menu_link_save($item);
  menu_cache_clear_all();

  return $output;

}

