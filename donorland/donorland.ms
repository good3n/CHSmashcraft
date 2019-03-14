// ############################################################
// # +------------------------------------------------------+ #
// # |               Donorland by Smashbox                  | #
// # +------------------------------------------------------+ #
// ############################################################

// prefix
@dl = '&5&lDonorland';

// define procs
proc(_dldie, @text,
  die(colorize(@dl.' &8\u00BB &7'.@text));
);

proc(_dlkill, @text,
  die(colorize(@dl.' &c\u00BB &7'.@text));
);

proc(_dlmsg, @text,
  msg(colorize(@dl. ' &a\u00BB &7'.@text));
);

proc(_dlexist,
	if(sk_region_exists(pworld(), 'dl-'.player())) {
    _dlkill('Uh.. you aready have '.@dl.'&7.');
  }
);

proc(_dlnoexist,
	if(!sk_region_exists(pworld(), 'dl-'.player())) {
    _dlkill('You do not have '.@dl.'&7.');
  }
);

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
          sk_region_flag(pworld(), @pregion, greeting, @dl.' &8\u00BB &7Welcome to &f'.@player.'\'s &7Donorland!');
          sk_region_flag(pworld(), @pregion, farewell, @dl.' &8\u00BB &7Now leaving &f'.@player.'\'s &7Donorland!');
          sk_region_flag(pworld(), @pregion, enderpearl, deny, NON_MEMBERS);
          sk_region_flag(pworld(), @pregion, 'blocked-cmds', '/sethome, /tpahere, /tpaccept', NON_MEMBERS);
          runas('~console', '/rg flag '.@pregion.' glide -w survival -g nonmembers deny');
          _dldie('Success! Your '.@dl.' &7has been claimed.');

        #===============================#
        # unclaim
        #===============================#
        case 'unclaim':

          // check if region exists
          if(!sk_region_exists(pworld(), @pregion)) {
            _dldie('You don\'t have any '.@dl.'&7 to unclaim.');
          }

          // require player confirmation
          _dlmsg('Are you sure? Type &a/confirm&7 or &c/cancel');
          @id = bind(player_command, null, null, @event, @pregion, @dl) {
            if(@event['command'] == '/confirm') {
              sk_region_remove(pworld(), @pregion);
              _dlmsg('You have unclaimed your '.@dl);
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

          // remove player region from regions list
          array_remove_values(@regions, @pregion);
          
          foreach(@regions, @oregion){

            // check if temp region is in other regions list
            if(to_lower(@oregion) != to_lower(@tempregion)) {

              // check if temp region overlaps other regions
              if(sk_region_overlaps(pworld(), @tempregion, @oregion)) {
                sk_region_remove(pworld(), @tempregion);
                _dldie('This claim is too close to &f'.@oregion.'&7. Try somewhere else.');
              }
            }
          }

          // pass overlap test and remove temp region
          sk_region_remove(pworld(), @tempregion);

          // require player confirmation
          _dlmsg('Are you sure? Type &a/confirm&7 or &c/cancel');
          @id = bind(player_command, null, null, @event, @pregion, @player, @loc, @dl) {
            if(@event['command'] == '/confirm') {
              if(has_permission('smash.donorland.t4')) {
                sk_region_update(pworld(), @pregion, array(array(@loc['x'] + 20, 255, @loc['z'] + 20), array(@loc['x'] - 20, 0, @loc['z'] - 20)));
              } else if(has_permission('smash.donorland.t6')) {
                sk_region_update(pworld(), @pregion, array(array(@loc['x'] + 25, 255, @loc['z'] + 25), array(@loc['x'] - 25, 0, @loc['z'] - 25)));
              } else if(has_permission('smash.donorland.t7')) {
                sk_region_update(pworld(), @pregion, array(array(@loc['x'] + 30, 255, @loc['z'] + 30), array(@loc['x'] - 30, 0, @loc['z'] - 30)));
              }
              _dlmsg('&aSuccess! &7You\'ve moved your '.@dl.' &7to \n&fx: '.ploc()[0].' z: '.ploc()[2]);
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

          _dlmsg('Information');

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
        case 'upgrade':

          // check if region exists
          if(!sk_region_exists(pworld(), @pregion)) {
            die(colorize('&cDerp. &7You don\'t have any &5Donorland &7claimed.'));
          }

          // get player donorland info
          @info = sk_region_info(@pregion, pworld(@player));

          // check donor perms
          if(has_permission('smash.donorland.t4')) {
            _dlkill('You must be &bTier 6 &7to upgrade your claim.');
          }
          if(has_permission('smash.donorland.t6') && @info[5] == '665856') {
            _dlkill('You are already upgraded to the max for your tier.');
          }
          if(has_permission('smash.donorland.t7') && @info[5] >= '952576') {
            _dlkill('You already have the largest available claim size. You beast.');
          }

          // create temp region for overlap test
          sk_region_create(pworld(), @tempregion, array(
            array(@info[0][0][0] + 50, 255, @info[0][0][2] + 50),
            array(@info[0][1][0] - 50, 0, @info[0][1][2] - 50)
          ));

          // get all regions
          @regions = sk_all_regions(pworld());

          // remove player region from regions list
          array_remove_values(@regions, @pregion);
          
          // loop through all regions
          foreach(@regions as @region) {

            // don't include temp region when checking regions
            if(@region != @tempregion) {

              // check if temp region overlaps other regions
              if(sk_region_overlaps(pworld(), @tempregion, @region)) {

                // fail, remove temp region
                sk_region_remove(pworld(), @tempregion);

                // die on fail
                msg('This claim is too close to &f'.@region.'&7. Try somewhere else.');
                
              }

            }

          }

          // pass, remove temp region
          sk_region_remove(pworld(), @tempregion);
          
          // require player confirmation
          _dlmsg('Are you ready to upgrade? Type &a/yes&7 or &c/no');
          @id = bind(player_command, null, null, @event, @pregion, @player, @info, @dl) {

            // if yes
            if(@event['command'] == '/yes') {

              sk_region_update(pworld(), @pregion, array(
                array(@info[0][0][0] + 5, 255, @info[0][0][2] + 5),
                array(@info[0][1][0] - 5, 0, @info[0][1][2] - 5)
              ));

              // check donor perms
              if(has_permission('smash.donorland.t6')) {
                _dlmsg('&7You upgraded your '.@dl.' &7to &f50x50&7!');
              }
              if(has_permission('smash.donorland.t7')) {
                _dlmsg('&7You upgraded your '.@dl.' &7to &f60x60&7!');
              }

            // if no
            } else if(@event['command'] == '/no') {
              _dlkill('Your donorland has not been upgraded!');

            // if anything else
            } else {
              _dlmsg('Upgrade canceled.');
            }
            unbind();
            cancel();
          }

          // if expires
          set_timeout(15000, closure(){
            if(has_bind(@id)) {
              unbind(@id);
              _dlmsg('&cCommand expired. &7Your donorland has not been upgraded.');
            }
          });

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