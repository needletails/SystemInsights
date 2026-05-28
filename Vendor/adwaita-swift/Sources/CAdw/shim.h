#include <adwaita.h>
#include <gtk/gtk.h>

static void
filedialog_on_open_cb (void *, void *, void *);
static void
filedialog_on_save_cb (void *, void *, void *);
static void
alertdialog_on_close_cb (void *, void *, void *);

static void
gtui_filedialog_save_finish (uint64_t dialog, uint64_t result, uint64_t data)
{
  GFile      *file = gtk_file_dialog_save_finish (dialog, result, NULL);
  const char *path = g_file_get_path (file);
  filedialog_on_save_cb (dialog, path, data);
  g_object_unref (file);
}

static void
gtui_filedialog_save (uint64_t dialog, uint64_t data, uint64_t window)
{
  swift_retain (data);
  gtk_file_dialog_save (dialog, window, NULL, G_CALLBACK (gtui_filedialog_save_finish), (void *)data);
}

static void
gtui_filedialog_open_finish (uint64_t dialog, uint64_t result, uint64_t data)
{
  GFile      *file = gtk_file_dialog_open_finish (dialog, result, NULL);
  if (file != NULL) {
    const char *path = g_file_peek_path (file);
    g_object_unref (file);
    filedialog_on_open_cb (dialog, path, data);
  } else {
    filedialog_on_open_cb (dialog, NULL, data);
  }
}

static void
gtui_filedialog_open (uint64_t dialog, uint64_t data, uint64_t window)
{
  swift_retain (data);
  gtk_file_dialog_open (dialog, window, NULL, G_CALLBACK (gtui_filedialog_open_finish), (void *)data);
}

static void
gtui_filedialog_open_folder_finish (uint64_t dialog, uint64_t result, uint64_t data)
{
  GFile      *file = gtk_file_dialog_select_folder_finish (dialog, result, NULL);
  if (file != NULL) {
    const char *path = g_file_peek_path (file);
    g_object_unref (file);
    filedialog_on_open_cb (dialog, path, data);
  } else {
    filedialog_on_open_cb (dialog, NULL, data);
  }
}

static void
gtui_filedialog_open_folder (uint64_t dialog, uint64_t data, uint64_t window)
{
  swift_retain (data);
  gtk_file_dialog_select_folder (dialog, window, NULL, G_CALLBACK (gtui_filedialog_open_folder_finish), (void *)data);
}

static void
gtui_alertdialog_cb (uint64_t dialog, uint64_t result, uint64_t data)
{
  const char *response = adw_alert_dialog_choose_finish (dialog, result);
  alertdialog_on_close_cb (dialog, response, data);
}

static void
gtui_alertdialog_choose (uint64_t dialog, uint64_t data, uint64_t parent)
{
  adw_alert_dialog_choose (dialog, parent, NULL, gtui_alertdialog_cb, data);
}

static GValue
gtui_initialize_boolean (gboolean boolean)
{
  GValue val = G_VALUE_INIT;
  g_value_init(&val, G_TYPE_BOOLEAN);
  g_value_set_boolean(&val, boolean);
  return val;
}

static void
gtui_cssprovider_set_prefers_color_scheme (uint64_t provider, GtkInterfaceColorScheme scheme)
{
  GValue val = G_VALUE_INIT;
  g_value_init(&val, G_TYPE_ENUM);
  g_value_set_enum(&val, scheme);
  g_object_set_property(provider, "prefers-color-scheme", &val);
  g_value_unset(&val);
}
