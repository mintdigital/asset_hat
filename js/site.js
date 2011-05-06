/*jslint  browser:  true,
          eqeqeq:   true,
          immed:    false,
          newcap:   true,
          nomen:    false,
          onevar:   true,
          plusplus: false,
          undef:    true,
          white:    false */
/*global  window, $ */



(function(w){

var loc = w.location;

function showSection(href){
  // `href` must work as both a URL hash *and* a CSS selector, e.g., `#foo`.

  var h = w.history,
      p = 'pushState',
      $target = $(href),
      animDuration = 500; // ms

  $('html, body').animate({ scrollTop: $target.offset().top }, animDuration);
  setTimeout(function(){
    // Update location hash, using history.pushState if available. This is
    // done in a `setTimeout` because, if done in a `$.fn.animate` callback,
    // it runs twice -- once per scrolled element.
    if(h[p]){ h[p](null, document.title, href); }
    loc.hash = href;
  }, animDuration);
}



/*** Navigation ***/

// If URL contains a hash, highlight that item in the nav
if(loc.hash !== ''){
  $(function(){
    var hash = loc.hash; // For removing chars in a URL before the hash

    if(hash !== ''){
      $('nav a').each(function(){
        var href = '#' + this.href.split('#')[1];
        if(href === hash){
          $(this).closest('li').addClass('current');
        }
      });
    }
  });
}

$('h1 a').live('click', function(ev){
  $('nav li.current').removeClass('current');
  showSection($(this).attr('href'));
  ev.preventDefault();
});

$('nav a').live('click', function(ev){
  var $a  = $(this),
      $li = $a.closest('li');

  $li.addClass('current').siblings().removeClass('current');
  showSection($a.attr('href'));
  ev.preventDefault();
});

// Highlight current section in nav while scrolling
$(function(){
  if($('header.site').css('position') !== 'fixed') { return; }

  var scrollTimeout, $sections = $('section');
  $(w).scroll(function(){
    if(scrollTimeout){
      clearTimeout(scrollTimeout);
      scrollTimeout = null;
    }
    scrollTimeout = setTimeout(function(){
      // User has finished scrolling
      $sections.each(function(i){
        var $section = $(this), currentSectionId;
        if( $section.offset().top + $section.height() >
            w.pageYOffset + Math.floor(w.innerHeight / 2) ){

          // Highlight current section in nav
          currentSectionId = $section.attr('id');
          if(currentSectionId === 'home'){
            $('nav li.current').removeClass('current');
          }else{
            $('nav a[href="#' + currentSectionId + '"]').closest('li').
              addClass('current').siblings().removeClass('current');
          }

          // Update URL anchor
          // w.location.hash = currentSectionId;
            // Disabled because this makes the jump while scrolling.

          // Stop looking for current section
          return false;
        }
      });
    }, 250);
  });
});



/*** Usage ***/

$(function(){
  var $toggleParent = $('#usage .comment-config').append(' '),
      $toggle  = $('<a class="toggle">(show)</a>').appendTo($toggleParent),
      $content = $toggleParent.siblings('.config');

  $toggle.click(function(){
    var klass = 'expanded';
    if($content.hasClass(klass)){
      $content.removeClass(klass);
      $toggle.html('(show)');
    }else{
      $content.addClass(klass);
      $toggle.html('(hide)');
    }
  });
});



})(window);
