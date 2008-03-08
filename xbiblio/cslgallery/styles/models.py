import datetime
from django.db import models, connection
from django.contrib.contenttypes.models import ContentType
from django.contrib.auth.models import User

class Category(models.Model):
    """CSL category."""
    name = models.SlugField(max_length=25, unique=True,
            help_text=u'Used in the URL for the category. Must be unique.')

    def __unicode__(self):   
        return (' ').join(self.name.split('-'))
        
    class Admin:
        pass

    class Meta:
        verbose_name = 'Style Category'
        verbose_name_plural = 'Style Categories'
        ordering = ['name']

    @models.permalink
    def permalink(self):
        return "cslgallery.styles.views.category_detail", [self.name]



class OptionType(models.Model):
    """CSL option type."""
    name = models.SlugField(max_length=30, unique=True,
           help_text=u'Used in the URL for the macro type. Must be unique.')

    def __unicode__(self):   
        return self.name
        
    class Admin:
        pass

    class Meta:
        verbose_name = 'Option Type'
        verbose_name_plural = 'Options Types'
        ordering = ['name']



class Option(models.Model):
    """CSL option."""
    type = models.ForeignKey(OptionType)
    value = models.CharField(max_length=15)
            
    def __unicode__(self):
        return u'%s = %s' % (self.type.name, self.value)
                                            
    class Admin:
        pass



class MacroType(models.Model):
    """CSL macro type. This is not in the CSL schema, but allows us to simplify management and GUI."""
    name = models.SlugField(max_length=40, unique=True,
                            help_text=u'Used in the URL for the macro type. Must be unique.')

    def __unicode__(self):  
        return (' ').join(self.name.split('-')) 
        
    class Admin:
        pass

    class Meta:
        verbose_name = 'Macro Type'
        ordering = ['name']



class Macro(models.Model):
    """CSL macro. This is really heart of the model, and the ease with which users
    will be able to create new styles will depend on a robust collection of macros."""
    type = models.ForeignKey(MacroType)
    slug = models.SlugField(unique=True,
                            help_text=u'Used in the URL for the macro. Must be unique.')
    # XMLField seems to be broken ATM; so just use TextField 
    # XMLField('~/xbiblio/csl/schema/trunk/csl-context.rng')
    xml = models.TextField()
    # preview = models.TextField()

    def __unicode__(self):
        return u'%s#%s' % (self.type.name, self.slug)

    class Admin:
        pass



class Context(models.Model):
    """ 
    A bundle of Options and a Layout, and a generic class 
    for bibliography and citation. 

    TODO: names and slugs? Sort macros?
    """
    CTYPE_CHOICES = (
        ('B', 'Bibliography'),
        ('C', 'Citation'),
    )
    name = models.CharField(max_length=100, unique=True)
    type = models.CharField(max_length=1, choices=CTYPE_CHOICES)
    # need to figure out how to constrain choices to Macro slug foreign key
    sort = models.ForeignKey(Macro, blank=True,
                             help_text=u'The macro to use for sorting.')
    options = models.ManyToManyField(Option, blank=True)
    layout_prefix = models.CharField(max_length=5, blank=True,
               help_text=u'The prefix for a citation or bibliography template.')
    layout_suffix = models.CharField(max_length=5, blank=True,
               help_text=u'The suffix for a citation or bibliography template.')

    def __unicode__(self):
        return self.name

    class Admin:
        pass

    class Meta:
        verbose_name = 'Citation/Bibliography Template'
        ordering = ['name']



class LayoutListItem(models.Model):
    """ 
    Associates a macro with a Context and tracks position in the list.
    """
    macro = models.ForeignKey(Macro)
    context = models.ForeignKey(Context)
    position = models.PositiveIntegerField(max_length=2, 
                 help_text=u'The index position of the macro within the layout list.')
    # hmm ... to include more formatting, or not?
    prefix = models.CharField(max_length=10)
    suffix = models.CharField(max_length=10)

    def __unicode__(self):
        return u'%s, %s, #%s' % (self.macro.slug, self.context.name, self.position)

    # need some methods to manipulate the list order

    class Admin:
        pass

    class Meta:
        verbose_name = 'Layout List Item'



class Style(models.Model):
    """CSL style."""
    STYPE_CHOICES = (
        ('1', 'in-text'),
        ('2', 'note'),
    )
    title = models.CharField(max_length=100)
    slug = models.SlugField(prepopulate_from=("title",), unique=True)
    type = models.CharField(max_length=1, choices=STYPE_CHOICES)
    categories = models.ManyToManyField(Category)
    author = models.ForeignKey(User)
    created = models.DateTimeField()
    updated = models.DateTimeField(default=datetime.datetime.now)
    citation = models.ForeignKey(Context, limit_choices_to={'type':'C'}, blank=True,
                                 related_name="styles_style_citation")
    bibliography = models.ForeignKey(Context, limit_choices_to={'type':'B'}, blank=True,
                                     related_name="styles_style_bibliography")

    def __unicode__(self):
        return self.title

    @models.permalink
    def permalink(self):
        return "cslgallery.styles.views.style_detail", [self.slug]

    class Admin:
        pass

    class Meta:
        ordering = ['title']

