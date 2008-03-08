# from django.conf.urls.defaults import *
# from cslgallery.styles.models import Style
# from cslgallery.styles.views import homepage
# 
# styles_dict = {
#    'queryset': Style.objects.all(),
# }
# 
# urlpatterns = patterns('',
#     # (r'^cslgallery/', include('cslgallery.foo.urls')),
#      (r'^admin/', include('django.contrib.admin.urls')),
#      (r'^styles/$', 'django.views.generic.list_detail.object_list', 
#                     dict(styles_dict, paginate_by=56, allow_empty=True, 
#                     template_name="styles/style_list.html")),
#      (r'^styles/(?P<slug>\d+)/$', 'django.views.generic.list_detail.object_detail', 
#                     dict(styles_dict, template_name="styles/style_detail.html")),
#      (r'^$', homepage)
# )

from django.conf import settings
from django.conf.urls.defaults import *
from django.views.static import serve
from cslgallery.styles.views import homepage
# from unipath import FSPath as Path

urlpatterns = patterns('',
    (r'^admin/', include('django.contrib.admin.urls')),
    (r'^styles/', include('cslgallery.styles.urls')),
    (r'^$', homepage),
)

# if settings.DEBUG:
#     urlpatterns += patterns('', 
#         (r'^m/(?P<path>.*)$', serve, {'document_root' : Path(__file__).parent.child("media")})
#     )
