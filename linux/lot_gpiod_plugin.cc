#include "include/lot_gpiod/lot_gpiod_plugin.h"

#include <cstring>
#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#define LOT_GPIOD_PLUGIN(obj)    \
    (G_TYPE_CHECK_INSTANCE_CAST( \
        (obj), lot_gpiod_plugin_get_type(), LotGpiodPlugin))

struct _LotGpiodPlugin {
    GObject parent_instance;
};

G_DEFINE_TYPE(LotGpiodPlugin, lot_gpiod_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void lot_gpiod_plugin_handle_method_call(LotGpiodPlugin *self,
                                                FlMethodCall *  method_call) {
    g_autoptr(FlMethodResponse) response = nullptr;

    const gchar *method = fl_method_call_get_name(method_call);

    if(strcmp(method, "getPlatformVersion") == 0) {
        struct utsname uname_data = {};
        uname(&uname_data);
        g_autofree gchar *version
            = g_strdup_printf("Linux %s", uname_data.version);
        g_autoptr(FlValue) result = fl_value_new_string(version);
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    } else {
        response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
    }

    fl_method_call_respond(method_call, response, nullptr);
}

static void lot_gpiod_plugin_dispose(GObject *object) {
    G_OBJECT_CLASS(lot_gpiod_plugin_parent_class)->dispose(object);
}

static void lot_gpiod_plugin_class_init(LotGpiodPluginClass *klass) {
    G_OBJECT_CLASS(klass)->dispose = lot_gpiod_plugin_dispose;
}

static void lot_gpiod_plugin_init(LotGpiodPlugin *self) {}

static void method_call_cb(FlMethodChannel *channel,
                           FlMethodCall *   method_call,
                           gpointer         user_data) {
    LotGpiodPlugin *plugin = LOT_GPIOD_PLUGIN(user_data);
    lot_gpiod_plugin_handle_method_call(plugin, method_call);
}

static gchar *get_executable_dir() {
    g_autoptr(GError) error    = nullptr;
    g_autofree gchar *exe_path = g_file_read_link("/proc/self/exe", &error);
    if(exe_path == nullptr) {
        g_critical("Failed to determine location of executable: %s",
                   error->message);
        return nullptr;
    }

    return g_path_get_dirname(exe_path);
}

void lot_gpiod_plugin_register_with_registrar(FlPluginRegistrar *registrar) {
    LotGpiodPlugin *plugin
        = LOT_GPIOD_PLUGIN(g_object_new(lot_gpiod_plugin_get_type(), nullptr));

    g_autofree gchar *executable_dir = get_executable_dir();
    g_autofree gchar *liblot_gpiod_path
        = g_build_filename(executable_dir, "lib", "libgpiod.so", nullptr);
    setenv("LIBLOT_GPIOD_PATH", liblot_gpiod_path, 0);

    g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
    g_autoptr(FlMethodChannel) channel
        = fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                                "lot_gpiod",
                                FL_METHOD_CODEC(codec));
    fl_method_channel_set_method_call_handler(
        channel, method_call_cb, g_object_ref(plugin), g_object_unref);

    g_object_unref(plugin);
}
