// ############################################################
// # +------------------------------------------------------+ #
// # |               Donorland by Smashbox                  | #
// # +------------------------------------------------------+ #
// ############################################################

// prefix
@prefix = '&a&lGuild';

// define procs
proc(_dldie, @text,
  die(colorize(@prefix.' &8\u00BB &7'.@text));
);

proc(_dlkill, @text,
  die(colorize(@prefix.' &c\u00BB &7'.@text));
);

proc(_dlmsg, @text,
  msg(colorize(@prefix. ' &2\u00BB &7'.@text));
);

proc(_dlexist,
	if(sk_region_exists(pworld(), 'dl-'.player())) {
    _dlkill('Uh.. you aready have '.@prefix.'&7.');
  }
);

proc(_dlnoexist,
	if(!sk_region_exists(pworld(), 'dl-'.player())) {
    _dlkill('You do not have '.@prefix.'&7.');
  }
);

register_command('guild2', array(

  'description': 'Guilds',
  'usage': '/guild',
  'permission': 'smash.guild',
  'noPermMsg': 'You do not have permission to use this command.',
  'aliases': array('g2', 'guilds2'),
  'executor': closure(@alias, @sender, @args, @info) {

      // check if any arguments
      if(array_size(@args) < 1) {
        foreach(split('\\n', read('../../LocalPackages/guilds/guilds.txt')), @msg) { msg(colorize(@msg)) }
        die();
      }

      @player = to_lower(player());
      @loc = ploc();
      @pregion = 'dl-'.@player;
      @tempregion = 'temp-'.@player;

      // check player world
      if(pworld(@player) != 'survival') {
        _dlkill('You are not in the right world to use this command.');
      }

      switch(@args[0]) { 

        #===============================#
        # claim
        #===============================#
        case 'claim':

          // check if region exists
          _dlexist;

          // create temp region for overlap check
          sk_region_create(pworld(), @tempregion, array(
            array(@loc['x'] + 50, 255, @loc['z'] + 50),
            array(@loc['x'] - 50, 0, @loc['z'] - 50)
          ));
          
          // get all regions
          foreach(sk_all_regions(pworld()), @region){

            // check if tempregion exists in foreach region above
            if(to_lower(@region) != to_lower(@tempregion)) {

              // conduct overlap test
              if(sk_region_overlaps(pworld(), @tempregion, @region)) {
                sk_region_remove(pworld(), @tempregion);
                _dldie('This claim is too close to &f'.@region.'&7. Try somewhere else.');
              }
            }
          }

          // pass overlap test
          sk_region_remove(pworld(), @tempregion);
          sk_region_create(pworld(), @pregion, array(array(@loc['x'] + 20, 255, @loc['z'] + 20), array(@loc['x'] - 20, 0, @loc['z'] - 20)));
          sk_region_addowner(@pregion, pworld(), @player);
          sk_region_flag(pworld(), @pregion, greeting, @prefix.' &8\u00BB &7Welcome to &f'.@player.'\'s &7Donorland!');
          sk_region_flag(pworld(), @pregion, farewell, @prefix.' &8\u00BB &7Now leaving &f'.@player.'\'s &7Donorland!');
          sk_region_flag(pworld(), @pregion, enderpearl, deny, NON_MEMBERS);
          sk_region_flag(pworld(), @pregion, 'blocked-cmds', '/sethome, /tpahere, /tpaccept', NON_MEMBERS);
          runas('~console', '/rg flag '.@pregion.' glide -w survival -g nonmembers deny');
          _dldie('Success! Your '.@prefix.' &7has been claimed.');
        
        default:
          _dlkill('Unrecognized command.');
      }  

  }

));