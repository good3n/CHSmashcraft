// ############################################################
// # +------------------------------------------------------+ #
// # |               Donorland by Smashbox                  | #
// # +------------------------------------------------------+ #
// ############################################################

proc(_dldie, @text,
  die(colorize('&5&lDonorland &8\u00BB &7'.@text))
);

proc(_dlkill, @text,
  die(colorize('&5&lDonorland &c\u00BB &7'.@text))
);

proc(_dlmsg, @text,
  msg(colorize('&5&lDonorland &a\u00BB &7'.@text))
);

proc _dlexists() {
  if(sk_region_exists(pworld(), 'dl-'.player())) {
    die(colorize('&5&lDonorland &c\u00BB &7Uh.. you aready have a claim?'))
  }
}

register_command('donorland', array(

  'description': 'Donorland land claiming',
  'usage': '/donorland',
  'permission': 'smash.donorland',
  'noPermMsg': 'You must be at least &aLord &7donor rank to use this command. Type &5/buy',
  'aliases': array('dl'),
  'executor': closure(@alias, @sender, @args, @info) {

      // check if any arguments
      if(array_size(@args) < 1) {
        foreach(split('\\n', read('../../LocalPackages/donorland/donorland.txt')), @msg) { msg(colorize(@msg)) }
        die();
      }

      @player = player();
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

          // vars
          @dloc = array(@loc['x'] + 20, @loc['y'], @loc['z'] - 20, pworld());

          // check if region exists
          _dlexists();

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
          sk_region_flag(pworld(), @pregion, greeting, '&5&lDonorland &8\u00BB &7Welcome to &f'.@player.'\'s &7Donorland!');
          sk_region_flag(pworld(), @pregion, farewell, '&5&lDonorland &8\u00BB &7Now leaving &f'.@player.'\'s &7Donorland!');
          sk_region_flag(pworld(), @pregion, enderpearl, deny, NON_MEMBERS);
          sk_region_flag(pworld(), @pregion, 'blocked-cmds', '/sethome, /tpahere, /tpaccept', NON_MEMBERS);
          runas('~console', '/rg flag '.@pregion.' glide -w survival -g nonmembers deny');
          _dldie('Success! Your &5&lDonorland &7has been claimed.');

        #===============================#
        # unclaim
        #===============================#
        case 'unclaim':

          // check if region exists
          if(!sk_region_exists(pworld(), @pregion)) {
            _dldie('You don\'t have any &5&lDonorland&7 to unclaim.');
          }

          // require player confirmation
          _dlmsg('Are you sure? Type &a/confirm&7 or &c/cancel');
          @id = bind(player_command, null, null, @event, @pregion) {
            if(@event['command'] == '/confirm') {
              sk_region_remove(pworld(), @pregion);
              _dlmsg('You have unclaimed your &5&lDonorland&7!');
            } else if(@event['command'] == '/cancel') {
              _dlmsg('Unclaiming canceled.');
            } else {
              _dlmsg('Unclaiming canceled.');
            }
            unbind();
            cancel();
          }
          set_timeout(15000, closure(){
            if(has_bind(@id)) {
              unbind(@id);
              _dlmsg('&cCommand expired. &7Unclaiming canceled.');
            }
          });

        #===============================#
        # trust
        #===============================#
        case 'trust':

          // check if player specified
          if(array_size(@args) < 2) {
            _dlkill('/donorland trust &8<&7player&8>');
          }

          // check if region exists
          if(!sk_region_exists(pworld(), @pregion)) {
            _dlkill('Derp. You have not yet made a claim.');
          }

          // require player confirmation
          @p = @args[1];
          _dlmsg('Are you sure? Type &a/confirm&7 or &c/cancel');
          @id = bind(player_command, null, null, @event, @pregion, @p) {
            if(@event['command'] == '/confirm') {
              runas('~console', '/rg addmember '.@pregion.' -w '.pworld().' -n '.@p);
              _dlmsg('Trusted&f '.@p);
            } else if(@event['command'] == '/cancel') {
              _dlmsg('&f'.@p.' &7was not trusted.');
            } else {
              _dlmsg('Trust request cancelled');
            }
            unbind();
            cancel();
          }
          set_timeout(15000, closure(){
            if(has_bind(@id)) {
              unbind(@id);
              _dlmsg('&cCommand expired. &f'.@p.' &7not trusted.');
            }
          });

        #===============================#
        # untrust
        #===============================#
        case 'untrust':

          // check if player specified
          if(array_size(@args) < 2) {
            _dlkill('/donorland untrust &8<&7player&8>');
          }
          
          // check if region exists
          if(!sk_region_exists(pworld(), @pregion)) {
            _dldie('Derp. You have not yet made a claim.');
          } else {
            // ugly uuid is ugly
            #sk_region_remmember(@pregion, pworld(), $player);
            runas('~console', '/rg removemember '.@pregion.' -w '.pworld().' -n '.@args[1]);
            _dldie('Untrusted&f '.@args[1]);
          }
        
        #===============================#
        # move
        #===============================#
        case 'move':
          // check if region exists
          if(!sk_region_exists(pworld(), @pregion)) {
            _dldie('&cDerp. &7You don\'t have any &5Donorland &7claimed.');
          }

          // create temp region for overlap test
          sk_region_create(pworld(), @tempregion, array(array(@loc['x'] + 50, 255, @loc['z'] + 50), array(@loc['x'] - 50, 0, @loc['z'] - 50)));
          
          // get all regions
          @regions = sk_all_regions(pworld());

          // remove this region from all regions list
          array_remove_values(@regions, @pregion);
          foreach(@regions, @oregions){

            // check if temp region is in other regions list
            if(to_lower(@oregions) != to_lower(@tempregion)) {

              // check if temp region overlaps other regions
              if(sk_region_overlaps(pworld(), @tempregion, @oregions)) {
                sk_region_remove(pworld(), @tempregion);
                _dldie('This claim is too close to &f'.@oregions.'&7. Try somewhere else.');
              }
            }
          }

          // pass overlap test and remove temp region
          sk_region_remove(pworld(), @tempregion);

          // require player confirmation
          _dlmsg('Are you sure? Type &a/confirm&7 or &c/cancel');
          @id = bind(player_command, null, null, @event, @pregion, @player, @loc) {
            if(@event['command'] == '/confirm') {
              if(has_permission('smash.donorland.t4')) {
                sk_region_update(pworld(), @pregion, array(array(@loc['x'] + 20, 255, @loc['z'] + 20), array(@loc['x'] - 20, 0, @loc['z'] - 20)));
              } else if(has_permission('smash.donorland.t6')) {
                sk_region_update(pworld(), @pregion, array(array(@loc['x'] + 25, 255, @loc['z'] + 25), array(@loc['x'] - 25, 0, @loc['z'] - 25)));
              } else if(has_permission('smash.donorland.t7')) {
                sk_region_update(pworld(), @pregion, array(array(@loc['x'] + 30, 255, @loc['z'] + 30), array(@loc['x'] - 30, 0, @loc['z'] - 30)));
              }
              _dlmsg('&aSuccess! &7You\'ve moved your &5&lDonorland &7to \n&fx: '.ploc()[0].' z: '.ploc()[2]);
            } else if(@event['command'] == '/cancel') {
              _dlmsg('Your donorland has not been moved.');
            } else {
              _dlmsg('Move canceled.');
            }
            unbind();
            cancel();
          }
          set_timeout(15000, closure(){
            if(has_bind(@id)) {
              unbind(@id);
              _dlmsg('&cCommand expired. &7Your donorland has not been moved.');
            }
          });
        
        #===============================#
        # info
        #===============================#
        case 'info':
          // check if region exists
          if(!sk_region_exists(pworld(), @pregion)) {
            _dldie('&cDerp. &7You don\'t have any &5Donorland &7claimed.');
          }

          // vars
          @xloc = array(sk_region_info(@pregion, 'survival', 0)[0][0]);
          @zloc = array(sk_region_info(@pregion, 'survival', 0)[0][2]);
          @flags = sk_region_flags(@pregion, pworld());
          @trustlist = sk_region_members(@pregion, pworld())[names]
          @players = array_implode(@trustlist, color(7).', '.color(f));
          
          msg(colorize('&5&lDonorland &8\u00BB &7Information'));;

          // check if player specified
          if(@players == '') {
            msg(colorize('&7Members&8: &fThere are no members added to your donorland.'));;
          } else {
            msg(colorize('&7Members&8: &f'.@players));;
          }

          // check greeting flag status
          if(!array_index_exists(@flags, 'greeting')) {
            msg(colorize('&7Greeting&8: &cNo greeting set.'));
          } else {
            msg(colorize('&7Greeting&8: &f'.@flags['greeting']));
          }

          // check farewell flag status
          if(!array_index_exists(@flags, 'farewell')) {
            msg(colorize('&7Farewell&8: &cNo farewell set.'));
          } else {
            msg(colorize('&7Farewell&8: &f'.@flags['farewell']));
          }

          // check location
          if(has_permission('smash.donorland.t4')) {
            msg(colorize('&7Location&8: &fx:'@xloc[0] - 20.'&7, &fz:'@zloc[0] - 20));
          } else if(has_permission('smash.donorland.t6')) {
            msg(colorize('&7Location&8: &fx:'@xloc[0] - 25.'&7, &fz:'@zloc[0] - 25));
          } else if(has_permission('smash.donorland.t7')) {
            msg(colorize('&7Location&8: &fx:'@xloc[0] - 30.'&7, &fz:'@zloc[0] - 30));
          } else {
            msg(colorize('&cUhhh, permission problem? Report to an admin.'));
          }

        #===============================#
        # upgrade
        #===============================#
        // case 'ugt':

        //   // check if region exists
        //   if(!sk_region_exists(pworld(), @pregion)) {
        //     _dldie('&cDerp. &7You don\'t have any &5Donorland &7claimed.');
        //   }

        //   @plots = sk_region_intersect(pworld(@player), @pregion);
        //   msg(@plots);

        #===============================#
        # flag: greeting
        #===============================#
        case 'greeting':

          if(array_size(@args) < 2) {
            _dlkill('/donorland greeting &8<&7message&8>');
          }

          // check if region exists
          if(!sk_region_exists(pworld(), @pregion)) {
            _dlkill('Derp. You have not yet made a claim.');
          } else {
            
            @msg = array_implode(@args[1..]);

            // set flag
            sk_region_flag(pworld(), @pregion, greeting, @msg);
            _dldie('Greeting set to&8: &f'.@msg);

          }
        
        #===============================#
        # flag: farewell
        #===============================#
        case 'farewell':

          if(array_size(@args) < 2) {
            _dlkill('/donorland farewell &8<&7message&8>');
          }

          // check if region exists
          if(!sk_region_exists(pworld(), @pregion)) {
            _dlkill('Derp. You have not yet made a claim.');
          } else {
            
            @msg = array_implode(@args[1..]);

            // set flag
            sk_region_flag(pworld(), @pregion, farewell, @msg);
            _dldie('Farewell set to&8: &f'.@msg);

          }
        
        default:
          _dlkill('Unrecognized command.');
      }  

  }

));