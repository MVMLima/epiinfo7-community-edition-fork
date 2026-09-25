using System;
using System.Drawing;
using System.Collections;
using System.ComponentModel;
using System.Windows.Forms;


namespace Epi.Windows.MakeView.Dialogs.FieldDefinitionDialogs
{
    /// <summary>
    /// The Text Field definition dialog
    /// </summary>
    public partial class TextFieldDefinition : GenericFieldDefinition
    {
        #region	Constructors
        /// <summary>
        /// Default Constsructor, for exclusive use by the designer.
        /// </summary>
        public TextFieldDefinition()
        {
            InitializeComponent();
        }
        /// <summary>
        /// Constructor for the class
        /// </summary>
        public TextFieldDefinition(MainForm frm)
            : base(frm)
        {
            InitializeComponent();
        }
        #endregion	Constructors

        #region Public Events
        private void chkReadOnly_CheckedChanged(object sender, EventArgs e)
        {
            if(!(((Control)sender).TopLevelControl is GUIDFieldDefinition))
            {
                chkRequired.Enabled = !chkReadOnly.Checked;
            }
        }

        private void chkRequired_CheckedChanged(object sender, EventArgs e)
        {
            if (!(((Control)sender).TopLevelControl is GUIDFieldDefinition))
            {
                chkReadOnly.Enabled = !chkRequired.Checked;
            }
        }
        #endregion Public Events

        private void chkEncrypted_CheckedChanged(object sender, EventArgs e)
        {
            if (sender is CheckBox && ((CheckBox)sender).Checked == true)
            {
                MessageBox.Show(global::Epi.SharedStrings.MSG_ENCRYPT_WARNING, global::Epi.SharedStrings.IMPORT_PREFIX_WARNING);
            }
        }
    }
}
