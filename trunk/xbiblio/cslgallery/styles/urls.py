from django.conf.urls.defaults import *
from django.views.generic import list_detail
from cslgallery.styles.models import Style, Category
from cslgallery.styles.views import style_detail, category_detail, search

style_info = {
    "queryset"              : Style.objects.all(),
    'template_name'         : "styles/style_list.html",
    'paginate_by'           : 100,
}

style_detail = {
    "queryset"              : Style.objects.all(),
    'template_name'         : "styles/detail.html",
}

category_info = {
    "queryset"              : Category.objects.all(),
    'template_name'         : "styles/category_list.html",
}

urlpatterns = patterns('',
    (r'^$', list_detail.object_list, style_info),
    (r'^by-category/$', list_detail.object_list, category_info),
    (r'^by-category/(?P<category_slug>[\w-]+)/$', category_detail),
    (r'^search/$', search),
    (r'^(?P<slug>.*)/$', list_detail.object_detail, style_detail),
)


