$(document).ready(function () {
    // Header
    $(".navbar-toggler").on("click", function () {
        $(this).toggleClass("open");
    });

    // Remove unwanted empty <p></p> tags
    $("p").each(function () {
        var $p = $(this);
        if ($.trim($p.html()) === "") {
            $p.remove();
        }
    });

    // Filter Section
    $(".filter__tab").click(function () {
        const tabData = $(this).attr("data-filter");

        // Add Class
        $(this).addClass("active").siblings().removeClass("active");

        // Specific Filters
        if (tabData === "all") {
            $(".filter__item").show("1000");
        } else {
            $(".filter__item")
                .not(".filter-" + tabData)
                .hide("1000");
            $(".filter__item")
                .filter(".filter-" + tabData)
                .show("1000");
        }

        // General Filters
        if (tabData === "all") {
            $(".regular-filter__item").show("1000");
        } else {
            $(".regular-filter__item")
                .not(".filter-" + tabData)
                .hide("1000");
            $(".regular-filter__item")
                .filter(".filter-" + tabData)
                .show("1000");
        }
    });

    // Search Filter
    jQuery("#search-field").on("keyup", function () {
        var txt_search_val = $(this).val().toLowerCase();
        jQuery.ajax({
            type: "POST",
            url: ajaxurl,
            dataType: "json",
            data: {
                action: "post_blog_text_search",
                txt_search_val: txt_search_val
            },
            success: function (resp) {
                $("#seach_text_ul").html(" ");
                if (resp.status == "success") {
                    if (resp.results.length != 0) {
                        $.each(resp.results, function (i, val) {
                            $("#seach_text_ul").append(
                                "<li><a href=" +
                                val.post_url +
                                " target='_blank'>" +
                                val.post_title +
                                "</a></li>"
                            );
                        });
                        $(".hero-banner__input-list").addClass("opened");
                    } else {
                        $(".hero-banner__input-list").removeClass("opened");
                    }
                }
            },
        });
    });
    if ($(".sk-slide").length > 0) {
        $('.sk-slide').slick({
            dots: false,
            adaptiveHeight: true,
            arrows: true,
        });
    }
    if ($(".mtp-items").length > 0) {
        $('.mtp-items').slick({
            dots: false,
            adaptiveHeight: true,
            slidesToShow: 4,
            arrows: true,
            slidesToScroll: 4,
            responsive: [
                {
                    breakpoint: 768,
                    settings: {
                        arrows: false,
                        centerMode: true,
                        centerPadding: '40px',
                        slidesToShow: 3
                    }
                },
                {
                    breakpoint: 480,
                    settings: {
                        arrows: false,
                        centerMode: true,
                        centerPadding: '40px',
                        slidesToShow: 1
                    }
                }
                ]
        });
    }
    if ($(".cs-customer-carusel").length > 0) {
        $('.cs-customer-carusel').slick({
            dots: false,
            adaptiveHeight: true,
            slidesToShow: 1,
            slidesToScroll: 1,
            centerMode: true,
            arrows: true,
            centerPadding: '500px',
            responsive: [
                {
                    breakpoint: 768,
                    settings: {
                        arrows: true,
                        centerMode: false,
                        slidesToShow: 1
                    }
                },
                {
                    breakpoint: 480,
                    settings: {
                        arrows: false,
                        centerMode: false,
                        slidesToShow: 1
                    }
                }
                ]
        });
    }
    if ($(".sk-slide2").length > 0) {
        $('.sk-slide2').slick({
            infinite: true,
            slidesToShow: 4,
            arrows: true,
            slidesToScroll: 4,
            responsive: [
                {
                    breakpoint: 768,
                    settings: {
                        arrows: false,
                        centerMode: true,
                        centerPadding: '40px',
                        slidesToShow: 3
                    }
                },
                {
                    breakpoint: 480,
                    settings: {
                        arrows: false,
                        centerMode: true,
                        centerPadding: '40px',
                        slidesToShow: 1
                    }
                }
                ]
        });
    }
    if ($(".key-benefits .apm-items").length > 0) {
        $('.key-benefits .apm-items').slick({
            infinite: true,
            slidesToShow: 3,
            arrows: true,
            draggable: false,
            slidesToScroll: 3,
            responsive: [
                {
                    breakpoint: 768,
                    settings: {
                        arrows: false,
                        centerMode: true,
                        centerPadding: '40px',
                        slidesToShow: 3
                    }
                },
                {
                    breakpoint: 480,
                    settings: {
                        arrows: false,
                        centerMode: true,
                        centerPadding: '40px',
                        slidesToShow: 1
                    }
                }
                ]
        });
    }
    /*if ($(".txc-stories .owl-carousels").length > 0) {
    $('.txc-stories .owl-carousels').slick({
        slidesToShow: 1,
        dots: true,
        vertical: true,
        draggable: true,
        variableWidth: false,
        verticalSwiping: true,
        swipeToSlide: true,
        accessibility: true,
        slidesToScroll: 1
    });
}*/


    // Slider Section
    if ($(".feedback-slider__main").length > 0) {
        $(".feedback-slider__main").slick({
            dots: true,
            adaptiveHeight: true,
        });
    }
});

$(window).on("load resize", function (event) {
    var mainHeader = $(".main-header");
    var mainBody = $("body");

    mainBody.css("padding-top", mainHeader.outerHeight());

    var topHeader = $(".top-header");
    var mainNav = $(".nav-wrapper");

    // Navbar Sticky
    $(window).bind("scroll", function () {
        if ($(window).scrollTop() > 120) {
            topHeader.addClass("hide");
            mainNav.css("top", "0px");
        } else {
            topHeader.removeClass("hide");
        }
    });
});

// Smooth scrolling using jQuery easing
$("a[href*='#']:not([href='#'])").click(function () {
    var navHeight;
    navHeight = document.getElementsByClassName("nav-wrapper")[0].offsetHeight;

    if (
        location.pathname.replace(/^\//, "") == this.pathname.replace(/^\//, "") &&
        location.hostname == this.hostname
    ) {
        var target = $(this.hash);
        target = target.length ? target : $("[name=" + this.hash.slice(1) + "]");
        if (target.length) {
            $("html, body").animate({
                    scrollTop: target.offset().top - (navHeight),
                },
                500
            );
            return 1;
        }
    }
});

jQuery(document).ready(function ($) {
    $('#txc-nfm-menu').sidr({
        name: 'sidr-main',
        source: '.txc-main-nav-n-inn .txc-main-menu',
        side: 'right'
    });

    $(".sidr-class-menu-close a").on('click', function () {
        $.sidr('close', 'sidr-main');
    });

    $(".sidr .sidr-class-wpmm-nav-wrap > ul.sidr-class-wp-megamenu > li.sidr-class-menu-item-has-children").on('click', function () {
        $(".sidr-class-wpmm-strees-row-container > ul.sidr-class-wp-megamenu-sub-menu").slideUp();
        $(this).children(".sidr-class-wpmm-strees-row-container").children("ul.sidr-class-wp-megamenu-sub-menu").slideToggle();
        $(this).addClass("submenu-open");
    });

    $(document).on('click', function (e) {
        if ($(e.target).closest('#sidr-main').length == 0) {

            $.sidr('close', 'sidr-main');
        }
    });

    $('.blg-search-klks').on('click', function () {
        $('.txc-n-search').toggleClass('search-form-expanded');
        $(this).toggleClass('img-xs');
    });

    $('.txc-n-search-in form input.search-field').attr('placeholder', 'Type and hit enter...');

    $('.cat-nav-for-nav').on('click', function () {
        $(this).parent().children('ul').slideToggle();
    });

    $('#lp-form .hbspt-form .hs-form').addClass('click-text');

    // TXC pop right
    setTimeout(function () {
        $('.txc-cp-pop').addClass('show')
    }, 5000);

    $('.txc-cp-close').on('click', function () {
        $(this).parent('.txc-cp-pop').removeClass('show');
    });

    // TXC blog search 
    $('.blgsk.blg-search-klks').on('click', function () {
        $('.txcnsw.txc-n-search').toggleClass('search-form-expanded');
        $(this).toggleClass('img-xs');
    });

});
