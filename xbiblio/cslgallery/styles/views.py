import urllib
from django.shortcuts import render_to_response, get_object_or_404
from django.template import RequestContext
from cslgallery.styles.models import Style, Category
from django.views.generic import list_detail
from django.contrib.contenttypes.models import ContentType
from django.db.models import Q

# some of this code is borrowed from http://www.cheeserater.com

def style_detail(request, slug):
    style = get_object_or_404(Style, s=slug)
    return list_detail.object_detail(
        request,
        queryset = Style.objects.all(),
    )

def homepage(request):
    style = Style.objects.order_by("?")[0]
    return style_detail(request, template_name="homepage.html")

def category_detail(request, category_slug):
    category = get_object_or_404(Category, slug=category_slug)
    return list_detail.object_list(
        request              = request,
        queryset             = category.style_set.all(),
        template_name        = "styles/style_by_category_list.html",
    )
    
def search(request):
    q = request.GET.get("q", "")
    if q and len(q) >= 3:
        clause = Q(title__icontains=q)                   \
               | Q(categories__name__icontains=q)
        qs = Style.objects.filter(clause).distinct()
    else:
        qs = Style.objects.none()
        
    return list_detail.object_list(
        request              = request,
        queryset             = qs,
        template_name        = "styles/search.html",
        paginate_by          = 100,
        extra_context        = {"q" : q},
    )
