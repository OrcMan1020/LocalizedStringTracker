//
//  FormatScaner.m
//
//  More detail please see GNUStep
//
//  Created by saix on 16/11/19.
//  Copyright © 2016年 citrix. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FormatScaner.h"

static inline const unichar *
find_spec (const unichar *format)
{
    while (*format && *format != '%') format++;
    return format;
}

struct printf_info
{
    int prec;			/* Precision.  */
    int width;			/* Width.  */
    unichar spec;			/* Format letter.  */
    unsigned int is_long_double:1;/* L flag.  */
    unsigned int is_short:1;	/* h flag.  */
    unsigned int is_long:1;	/* l flag.  */
    unsigned int alt:1;		/* # flag.  */
    unsigned int space:1;		/* Space flag.  */
    unsigned int left:1;		/* - flag.  */
    unsigned int showsign:1;	/* + flag.  */
    unsigned int group:1;		/* ' flag.  */
    unsigned int extra:1;		/* For special use.  */
    unsigned int is_char:1;	/* hh flag.  */
    unsigned int wide:1;		/* Nonzero for wide character streams.  */
    unsigned int i18n:1;		/* I flag.  */
    unichar pad;			/* Padding character.  */
};

struct printf_spec
{
    /* Information parsed from the format spec.  */
    struct printf_info info;
    
    /* Pointers into the format string for the end of this format
     spec and the next (or to the end of the string if no more).  */
    const unichar *end_of_fmt, *next_fmt;
    
    /* Position of arguments for precision and width, or -1 if `info' has
     the constant value.  */
    int prec_arg, width_arg;
    
    int data_arg;		/* Position of data argument.  */
    int data_arg_type;		/* Type of first argument.  */
    /* Number of arguments consumed by this format specifier.  */
    size_t ndata_args;
};

/* The various kinds off arguments that can be passed to printf.  */
union printf_arg
{
    unsigned char pa_char;
    wchar_t pa_wchar;
    short int pa_short_int;
    int pa_int;
    long int pa_long_int;
    long long int pa_long_long_int;
    unsigned short int pa_u_short_int;
    unsigned int pa_u_int;
    unsigned long int pa_u_long_int;
    unsigned long long int pa_u_long_long_int;
    float pa_float;
    double pa_double;
    long double pa_long_double;
    const char *pa_string;
    const wchar_t *pa_wstring;
    id pa_object;
    void *pa_pointer;
};

enum
{				/* C type: */
    PA_INT,			/* int */
    PA_CHAR,			/* int, cast to char */
    PA_WCHAR,			/* wide char */
    PA_STRING,			/* const char *, a '\0'-terminated string */
    PA_WSTRING,			/* const wchar_t *, wide character string */
    PA_POINTER,			/* void * */
    PA_FLOAT,			/* float */
    PA_DOUBLE,			/* double */
    PA_OBJECT,			/* id */
    PA_LAST
};

/* Flag bits that can be set in a type returned by `parse_printf_format'.  */
#define	PA_FLAG_MASK		0xff00
#define	PA_FLAG_LONG_LONG	(1 << 8)
#define	PA_FLAG_LONG_DOUBLE	PA_FLAG_LONG_LONG
#define	PA_FLAG_LONG		(1 << 9)
#define	PA_FLAG_SHORT		(1 << 10)
#define	PA_FLAG_PTR		(1 << 11)

#  define ISDIGIT(Ch)	((unsigned int) ((Ch) - '0') < 10)

static inline unsigned int
read_int (const unichar * *pstr)
{
    unsigned int retval = **pstr - '0';
    
    while (ISDIGIT (*++(*pstr)))
    {
        retval *= 10;
        retval += **pstr - '0';
    }
    
    return retval;
}

static inline size_t
parse_one_spec (const unichar *format, size_t posn, struct printf_spec *spec,
                size_t *max_ref_arg)
{
    unsigned int n;
    size_t nargs = 0;
    
    /* Skip the '%'.  */
    ++format;
    
    /* Clear information structure.  */
    spec->data_arg = -1;
    spec->info.alt = 0;
    spec->info.space = 0;
    spec->info.left = 0;
    spec->info.showsign = 0;
    spec->info.group = 0;
    spec->info.i18n = 0;
    spec->info.pad = ' ';
    spec->info.wide = sizeof (unichar) > 1;
    
    /* Test for positional argument.  */
    if (ISDIGIT (*format))
    {
        const unichar *begin = format;
        
        n = read_int (&format);
        
        if (n > 0 && *format == '$')
        /* Is positional parameter.  */
        {
            ++format;		/* Skip the '$'.  */
            spec->data_arg = n - 1;
            *max_ref_arg = MAX (*max_ref_arg, n);
        }
        else
        /* Oops; that was actually the width and/or 0 padding flag.
         Step back and read it again.  */
            format = begin;
    }
    
    /* Check for spec modifiers.  */
    do
    {
        switch (*format)
        {
            case ' ':
                /* Output a space in place of a sign, when there is no sign.  */
                spec->info.space = 1;
                continue;
            case '+':
                /* Always output + or - for numbers.  */
                spec->info.showsign = 1;
                continue;
            case '-':
                /* Left-justify things.  */
                spec->info.left = 1;
                continue;
            case '#':
                /* Use the "alternate form":
                 Hex has 0x or 0X, FP always has a decimal point.  */
                spec->info.alt = 1;
                continue;
            case '0':
                /* Pad with 0s.  */
                spec->info.pad = '0';
                continue;
            case '\'':
                /* Show grouping in numbers if the locale information
                 indicates any.  */
                spec->info.group = 1;
                continue;
            case 'I':
                /* Use the internationalized form of the output.  Currently
                 means to use the `outdigits' of the current locale.  */
                spec->info.i18n = 1;
                continue;
            default:
                break;
        }
        break;
    }
    while (*++format);
    
    if (spec->info.left)
        spec->info.pad = ' ';
    
    /* Get the field width.  */
    spec->width_arg = -1;
    spec->info.width = 0;
    if (*format == '*')
    {
        /* The field width is given in an argument.
         A negative field width indicates left justification.  */
        const unichar *begin = ++format;
        
        if (ISDIGIT (*format))
        {
            /* The width argument might be found in a positional parameter.  */
            n = read_int (&format);
            
            if (n > 0 && *format == '$')
            {
                spec->width_arg = n - 1;
                *max_ref_arg = MAX (*max_ref_arg, n);
                ++format;		/* Skip '$'.  */
            }
        }
        
        if (spec->width_arg < 0)
        {
            /* Not in a positional parameter.  Consume one argument.  */
            spec->width_arg = posn++;
            ++nargs;
            format = begin;	/* Step back and reread.  */
        }
    }
    else if (ISDIGIT (*format))
    /* Constant width specification.  */
        spec->info.width = read_int (&format);
    
    /* Get the precision.  */
    spec->prec_arg = -1;
    /* -1 means none given; 0 means explicit 0.  */
    spec->info.prec = -1;
    if (*format == '.')
    {
        ++format;
        if (*format == '*')
        {
            /* The precision is given in an argument.  */
            const unichar *begin = ++format;
            
            if (ISDIGIT (*format))
            {
                n = read_int (&format);
                
                if (n > 0 && *format == '$')
                {
                    spec->prec_arg = n - 1;
                    *max_ref_arg = MAX (*max_ref_arg, n);
                    ++format;
                }
            }
            
            if (spec->prec_arg < 0)
            {
                /* Not in a positional parameter.  */
                spec->prec_arg = posn++;
                ++nargs;
                format = begin;
            }
        }
        else if (ISDIGIT (*format))
            spec->info.prec = read_int (&format);
        else
        /* "%.?" is treated like "%.0?".  */
            spec->info.prec = 0;
    }
    
    /* Check for type modifiers.  */
    spec->info.is_long_double = 0;
    spec->info.is_short = 0;
    spec->info.is_long = 0;
    spec->info.is_char = 0;
    
    switch (*format++)
    {
        case 'h':
            /* ints are short ints or chars.  */
            if (*format != 'h')
                spec->info.is_short = 1;
            else
            {
                ++format;
                spec->info.is_char = 1;
            }
            break;
        case 'l':
            /* ints are long ints.  */
            spec->info.is_long = 1;
            if (*format != 'l')
                break;
            ++format;
            /* FALLTHROUGH */
        case 'L':
            /* doubles are long doubles, and ints are long long ints.  */
        case 'q':
            /* 4.4 uses this for long long.  */
            spec->info.is_long_double = 1;
            break;
        case 'z':
        case 'Z':
            /* ints are size_ts.  */
            NSCParameterAssert (sizeof (size_t) <= sizeof (unsigned long long int));
#if defined(LLONG_MAX)
#if LONG_MAX != LLONG_MAX
            spec->info.is_long_double = sizeof (size_t) > sizeof (unsigned long int);
#endif
#endif
            spec->info.is_long = sizeof (size_t) > sizeof (unsigned int);
            break;
        case 't':
            NSCParameterAssert (sizeof (ptrdiff_t) <= sizeof (long long int));
#if defined(LLONG_MAX)
#if LONG_MAX != LLONG_MAX
            spec->info.is_long_double = (sizeof (ptrdiff_t) > sizeof (long int));
#endif
#endif
            spec->info.is_long = sizeof (ptrdiff_t) > sizeof (int);
            break;
        case 'j':
            NSCParameterAssert (sizeof (uintmax_t) <= sizeof (unsigned long long int));
#if defined(LLONG_MAX)
#if LONG_MAX != LLONG_MAX
            spec->info.is_long_double = (sizeof (uintmax_t)
                                         > sizeof (unsigned long int));
#endif
#endif
            spec->info.is_long = sizeof (uintmax_t) > sizeof (unsigned int);
            break;
        default:
            /* Not a recognized modifier.  Backup.  */
            --format;
            break;
    }
    
    /* Get the format specification.  */
    spec->info.spec = (unichar) *format++;
    {
        /* Find the data argument types of a built-in spec.  */
        spec->ndata_args = 1;
        
        switch (spec->info.spec)
        {
            case 'i':
            case 'd':
            case 'u':
            case 'o':
            case 'X':
            case 'x':
#if defined(LLONG_MAX)
#if LONG_MAX != LLONG_MAX
                if (spec->info.is_long_double)
                    spec->data_arg_type = PA_INT|PA_FLAG_LONG_LONG;
                else
#endif
#endif
                    if (spec->info.is_long)
                        spec->data_arg_type = PA_INT|PA_FLAG_LONG;
                    else if (spec->info.is_short)
                        spec->data_arg_type = PA_INT|PA_FLAG_SHORT;
                    else if (spec->info.is_char)
                        spec->data_arg_type = PA_CHAR;
                    else
                        spec->data_arg_type = PA_INT;
                break;
            case 'e':
            case 'E':
            case 'f':
            case 'F':
            case 'g':
            case 'G':
            case 'a':
            case 'A':
                if (spec->info.is_long_double)
                    spec->data_arg_type = PA_DOUBLE|PA_FLAG_LONG_DOUBLE;
                else
                    spec->data_arg_type = PA_DOUBLE;
                break;
            case 'c':
                spec->data_arg_type = PA_CHAR;
                break;
            case 'C':
                spec->data_arg_type = PA_WCHAR;
                break;
            case 's':
                spec->data_arg_type = PA_STRING;
                break;
            case 'S':
                spec->data_arg_type = PA_WSTRING;
                break;
            case '@':
                spec->data_arg_type = PA_OBJECT;
                break;
            case 'p':
                spec->data_arg_type = PA_POINTER;
                break;
            case 'n':
                spec->data_arg_type = PA_INT|PA_FLAG_PTR;
                break;
                
            case 'm':
            default:
                /* An unknown spec will consume no args.  */
                spec->ndata_args = 0;
                break;
        }
    }
    
    if (spec->data_arg == -1 && spec->ndata_args > 0)
    {
        /* There are args consumed, but no positional spec.  Use the
         next sequential arg position.  */
        spec->data_arg = posn;
        nargs += spec->ndata_args;
    }
    
    if (spec->info.spec == '\0')
    /* Format ended before this spec was complete.  */
        spec->end_of_fmt = spec->next_fmt = format - 1;
    else
    {
        /* Find the next format spec.  */
        spec->end_of_fmt = format;
        spec->next_fmt = find_spec (format);
    }
    
    return nargs;
}


@implementation FormatScaner

+(NSArray*)scanWithFormat:(NSString*)format andOutput:(NSMutableArray*)outputArray, ...
{
    va_list ap;
    va_start(ap, outputArray);
    NSArray* array = [[self class] scanWithFormat:format locale:nil arguments:ap andOutput:outputArray];
    va_end(ap);

    return array;
}

+(NSArray*)scanWithFormat:(NSString*)format locale:(NSDictionary*)locale arguments: (va_list)argList andOutput:(NSMutableArray*)outputArray
{
//    unsigned char	buf[2048];
    unichar	fbuf[1024];
    unichar	*fmt = fbuf;

    size_t	len;
    
    len = [format length];
    if (len >= 1024)
    {
        fmt = NSZoneMalloc(NSDefaultMallocZone(), (len+1)*sizeof(unichar));
    }
    [format getCharacters: fmt range: ((NSRange){0, len})];
    fmt[len] = '\0';

    
    //GSPrivateFormat(fmt, locale, argList);
    NSArray* array = [[self class] PrivateFormat:fmt locale:locale arguments:argList andOutput:outputArray];
//    NSLog(@"%@", array);
    
    return array;
    
}


+(NSArray*)PrivateFormat:(const unichar *)format locale:(NSDictionary*)locale arguments: (va_list)ap andOutput:(NSMutableArray*)objectArray
{
    
//    NSMutableArray* objectArray = [[NSMutableArray alloc] init];
    /* The character used as thousands separator.  */
    NSString *thousands_sep = @"";
    
    /* The string describing the size of groups of digits.  */
    const char *grouping;
    
    /* Place to accumulate the result.  */
    int done;
    
    /* Current character in format string.  */
    const unichar *f;
    
    /* End of leading constant string.  */
    const unichar *lead_str_end;
    
    /* Points to next format specifier.  */
    
    /* Buffer intermediate results.  */
    unichar work_buffer[1000];
    unichar *workend;
    int workend_malloced = 0;
    
    /* State for restartable multibyte character handling functions.  */
    
    /* We have to save the original argument pointer.  */
    va_list ap_save;
    
    /* Count number of specifiers we already processed.  */
    int nspecs_done;
    
    /* For the %m format we may need the current `errno' value.  */
    int save_errno = errno;
    
    
    /* This table maps a character into a number representing a
     class.  In each step there is a destination label for each
     class.  */
    static const int jump_table[] =
    {
        /* ' ' */  1,            0,            0, /* '#' */  4,
	       0, /* '%' */ 14,            0, /* '\''*/  6,
	       0,            0, /* '*' */  7, /* '+' */  2,
	       0, /* '-' */  3, /* '.' */  9,            0,
        /* '0' */  5, /* '1' */  8, /* '2' */  8, /* '3' */  8,
        /* '4' */  8, /* '5' */  8, /* '6' */  8, /* '7' */  8,
        /* '8' */  8, /* '9' */  8,            0,            0,
	       0,            0,            0,            0,
        /* '@' */ 30, /* 'A' */ 26,            0, /* 'C' */ 25,
	       0, /* 'E' */ 19, /* F */   19, /* 'G' */ 19,
	       0, /* 'I' */ 29,            0,            0,
        /* 'L' */ 12,            0,            0,            0,
	       0,            0,            0, /* 'S' */ 21,
	       0,            0,            0,            0,
        /* 'X' */ 18,            0, /* 'Z' */ 13,            0,
	       0,            0,            0,            0,
	       0, /* 'a' */ 26,            0, /* 'c' */ 20,
        /* 'd' */ 15, /* 'e' */ 19, /* 'f' */ 19, /* 'g' */ 19,
        /* 'h' */ 10, /* 'i' */ 15, /* 'j' */ 28,            0,
        /* 'l' */ 11, /* 'm' */ 24, /* 'n' */ 23, /* 'o' */ 17,
        /* 'p' */ 22, /* 'q' */ 12,            0, /* 's' */ 21,
        /* 't' */ 27, /* 'u' */ 16,            0,            0,
        /* 'x' */ 18,            0, /* 'z' */ 13
    };
    
#define NOT_IN_JUMP_RANGE(Ch) ((Ch) < ' ' || (Ch) > 'z')
#define CHAR_CLASS(Ch) (jump_table[(wint_t) (Ch) - ' '])
# define JUMP_TABLE_TYPE const void *const
    
    /* Initialize local variables.  */
    done = 0;
    grouping = (const char *) -1;
#ifdef __va_copy
    /* This macro will be available soon in gcc's <stdarg.h>.  We need it
     since on some systems `va_list' is not an integral type.  */
    __va_copy (ap_save, ap);
#else
    ap_save = ap;
#endif
    nspecs_done = 0;
    
    /* Find the first format specifier.  */
    f = lead_str_end = find_spec ((const unichar *) format);
    
    
//    /* Write the literal text before the first format.  */
//    outstring ((const unichar *) format,
//               lead_str_end - (const unichar *) format);
    
    /* If we only have to print a simple string, return now.  */
    if (*f == '\0')
        goto all_done;
    
    /* Process whole format string.  */
    
    workend = &work_buffer[sizeof (work_buffer) / sizeof (unichar)];
    
    /* Here starts the more complex loop to handle positional parameters.  */
    {
        /* Array with information about the needed arguments.  This has to
         be dynamically extensible.  */
        size_t nspecs = 0;
        size_t nspecs_max = 32;	/* A more or less arbitrary start value.  */
        struct printf_spec *specs
        = alloca (nspecs_max * sizeof (struct printf_spec));
        
        /* The number of arguments the format string requests.  This will
         determine the size of the array needed to store the argument
         attributes.  */
        size_t nargs = 0;
        int *args_type;
        union printf_arg *args_value = NULL;
        
        /* Positional parameters refer to arguments directly.  This could
         also determine the maximum number of arguments.  Track the
         maximum number.  */
        size_t max_ref_arg = 0;
        
        /* Just a counter.  */
        size_t cnt;
        
        
        if (grouping == (const char *) -1)
        {
            static NSString *NSThousandsSeparator = @"NSThousandsSeparator";

            thousands_sep = [locale objectForKey: NSThousandsSeparator];
            if (thousands_sep == nil) thousands_sep = @",";
            
            grouping = ""; // FIXME: grouping info missing in locale?
            if (*grouping == '\0' || *grouping == CHAR_MAX)
                grouping = NULL;
        }
        
        for (f = lead_str_end; *f != '\0'; f = specs[nspecs++].next_fmt)
        {
            if (nspecs >= nspecs_max)
            {
                /* Extend the array of format specifiers.  */
                struct printf_spec *old = specs;
                
                nspecs_max *= 2;
                specs = alloca (nspecs_max * sizeof (struct printf_spec));
                
                if (specs == &old[nspecs])
                /* Stack grows up, OLD was the last thing allocated;
                 extend it.  */
                    nspecs_max += nspecs_max / 2;
                else
                {
                    /* Copy the old array's elements to the new space.  */
                    memcpy (specs, old, nspecs * sizeof (struct printf_spec));
                    if (old == &specs[nspecs])
                    /* Stack grows down, OLD was just below the new
                     SPECS.  We can use that space when the new space
                     runs out.  */
                        nspecs_max += nspecs_max / 2;
                }
            }
            
            /* Parse the format specifier.  */
            nargs += parse_one_spec (f, nargs, &specs[nspecs], &max_ref_arg);
        }
        
        /* Determine the number of arguments the format string consumes.  */
        nargs = MAX (nargs, max_ref_arg);
//        NSLog(@"%lu args", nargs);
        
        /* Allocate memory for the argument descriptions.  */
        args_type = alloca (nargs * sizeof (int));
        memset (args_type, 0, nargs * sizeof (int));
        args_value = alloca (nargs * sizeof (union printf_arg));
        
        /* XXX Could do sanity check here: If any element in ARGS_TYPE is
         still zero after this loop, format is invalid.  For now we
         simply use 0 as the value.  */
        
        /* Fill in the types of all the arguments.  */
        for (cnt = 0; cnt < nspecs; ++cnt)
        {
            /* If the width is determined by an argument this is an int.  */
            if (specs[cnt].width_arg != -1)
                args_type[specs[cnt].width_arg] = PA_INT;
            
            /* If the precision is determined by an argument this is an int.  */
            if (specs[cnt].prec_arg != -1)
                args_type[specs[cnt].prec_arg] = PA_INT;
            
            switch (specs[cnt].ndata_args)
            {
                case 0:		/* No arguments.  */
                    break;
                case 1:		/* One argument; we already have the type.  */
                    args_type[specs[cnt].data_arg] = specs[cnt].data_arg_type;
                    break;
                default:
                    /* ??? */
                    break;
            }
        }
        
        
        /* Now we know all the types and the order.  Fill in the argument
         values.  */
        for (cnt = 0; cnt < nargs; ++cnt)
            switch (args_type[cnt])
        {
#define T(tag, mem, type)						      \
case tag:							      \
args_value[cnt].mem = va_arg (ap_save, type);			      \
break
                
                T (PA_CHAR, pa_char, int); /* Promoted.  */
                T (PA_WCHAR, pa_wchar, int); /* Sometimes promoted.  */
                T (PA_INT|PA_FLAG_SHORT, pa_short_int, int); /* Promoted.  */
                T (PA_INT, pa_int, int);
                T (PA_INT|PA_FLAG_LONG, pa_long_int, long int);
                T (PA_INT|PA_FLAG_LONG_LONG, pa_long_long_int, long long int);
                T (PA_FLOAT, pa_float, double);	/* Promoted.  */
                T (PA_DOUBLE, pa_double, double);
                T (PA_DOUBLE|PA_FLAG_LONG_DOUBLE, pa_long_double, long double);
                T (PA_STRING, pa_string, const char *);
                T (PA_WSTRING, pa_wstring, const wchar_t *);
                T (PA_OBJECT, pa_object, id);
                T (PA_POINTER, pa_pointer, void *);
#undef T
            default:
                if ((args_type[cnt] & PA_FLAG_PTR) != 0)
                    args_value[cnt].pa_pointer = va_arg (ap_save, void *);
                else
                    args_value[cnt].pa_long_double = 0.0;
                break;
        }
        
        for(cnt = 0; cnt < nargs; ++cnt){
            if(args_type[cnt] == PA_OBJECT){
                id value = (id)(args_value[cnt].pa_object);
//                if(value == nil){
//                    value = [NSNull null];
//                }
//                NSLog(@"%@", [value class]);
//                NSLog(@"%@", value);
//
                
                if(value && [value isKindOfClass:[NSString class]]){
                    [objectArray addObject:value];
                }
                
            }
        }
    }
    
    all_done:
        return objectArray;

}
@end
    
    
